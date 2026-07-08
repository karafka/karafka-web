# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Namespace for consumer sub-components
      module Consumers
        module Aggregators
          # Aggregator that tracks consumers processes states, aggregates the metrics and converts
          # data points into a materialized current state.
          #
          # There are two types of metrics:
          #   - totals - metrics that represent absolute values like number of messages processed
          #     in total. Things that need to be incremented/updated with each incoming consumer
          #     process report. They cannot be "batch computed" because they do not represent a
          #     a state of time but progress.
          #   - aggregated state - a state that represents a "snapshot" of things happening right
          #     now. Right now is the moment of time on which we operate.
          class State < Base
            # Current schema version
            # This can be used in the future for detecting incompatible changes and writing
            # migrations
            SCHEMA_VERSION = "1.5.0"

            # @param schema_manager [Karafka::Web::Processing::Consumers::SchemaManager] schema
            #   manager that tracks the compatibility of schemas.
            def initialize(schema_manager)
              super()
              @schema_manager = schema_manager
              # [cg_id, topic_name, partition_id] => @aggregated_from value when we first
              # observed that partition as paused. See #track_paused_partitions.
              @paused_since = {}
              @paused_partitions_lag_refreshed_at = nil
            end

            # Uses provided process state report to update the current materialized state
            # @param report [Hash] consumer process state report
            # @param offset [Integer] offset of the message with the state report. This offset is
            #   needed as we need to be able to get all the consumers reports from a given offset.
            def add(report, offset)
              super(report)
              increment_total_counters(report)
              add_state(report, offset)
              # We always evict after counters updates because we want to use expired (stopped)
              # data for counters as it was valid previously. This can happen only when web consumer
              # had a lag and is catching up.
              evict_expired_processes
              # current means current in the context of processing window (usually now but in case
              # of lag, this state may be from the past)
              refresh_current_stats
              track_paused_partitions
              refresh_paused_partitions_lag
            end

            # Registers or updates the given process state based on the report
            #
            # @param report [Hash]
            # @param offset [Integer]
            def add_state(report, offset)
              # When we deserialize the keys from the stored state, because we convert keys into
              # symbols, we may have given process state already stored. This means that in order
              # to update it, we do need to have the new report process id also as a symbol to
              # act as the key
              process_id = report[:process][:id].to_sym

              state[:processes][process_id] = {
                dispatched_at: report[:dispatched_at],
                offset: offset
              }
            end

            # @return [Array<Hash, Float>] aggregated current stats value and time from which this
            #   aggregation comes from
            #
            # @note We return a copy, because we use the internal one to track state changes and
            #   unless we would return a copy, other aggregators could have this mutated in an
            #   unexpected way
            def stats
              state.fetch(:stats).dup
            end

            # Sets the dispatch time and returns the hash that can be shipped to the states topic
            #
            # @param _args [Object] extra parsing arguments (not used)
            # @return [Hash] Hash that we can use to ship states data to Kafka
            def to_h(*_args)
              state[:schema_version] = SCHEMA_VERSION
              state[:dispatched_at] = float_now
              state[:schema_state] = @schema_manager.to_s

              state
            end

            private

            # @return [Hash] hash with current state from Kafka
            def state
              @state ||= Consumers::State.current!
            end

            # Increments the total counters based on the provided report
            # @param report [Hash]
            def increment_total_counters(report)
              report[:stats][:total].each do |key, value|
                state[:stats][key] ||= 0
                state[:stats][key] += value
              end
            end

            # Evicts expired processes from the current state
            # We consider processes dead if they do not report often enough
            # @note We do not evict based on states (stopped), because we want to report the
            #   stopped processes for extra time within the ttl limitations. This makes tracking of
            #   things from UX perspective nicer.
            def evict_expired_processes
              max_ttl = @aggregated_from - (::Karafka::Web.config.ttl / 1_000)

              state[:processes].delete_if do |_id, details|
                details[:dispatched_at] < max_ttl
              end

              @active_reports.delete_if do |_id, details|
                details[:dispatched_at] < max_ttl
              end
            end

            # Refreshes the counters that are computed based on incoming reports and not a
            # total sum.
            # For this we use active reports we have in memory. It may not be accurate for the first
            # few seconds but it is much more optimal from performance perspective than computing
            # this fetching all data from Kafka for each view.
            def refresh_current_stats
              stats = state[:stats]

              stats[:busy] = 0
              stats[:enqueued] = 0
              stats[:waiting] = 0
              stats[:workers] = 0
              stats[:processes] = 0
              stats[:rss] = 0
              stats[:listeners] = { active: 0, standby: 0 }
              stats[:lag_hybrid] = 0
              stats[:bytes_received] = 0
              stats[:bytes_sent] = 0
              utilization = 0

              @active_reports
                .values
                .reject { |report| report[:process][:status] == "stopped" }
                .each do |report|
                  report_stats = report[:stats]
                  report_process = report[:process]

                  lags_hybrid = []

                  iterate_partitions(report) do |partition_stats|
                    lag_stored = partition_stats[:lag_stored]
                    lag = partition_stats[:lag]

                    lags_hybrid << (lag_stored.negative? ? lag : lag_stored)
                  end

                  stats[:busy] += report_stats[:busy]
                  stats[:enqueued] += report_stats[:enqueued]
                  stats[:waiting] += report_stats[:waiting] || 0
                  stats[:workers] += report_process[:workers] || 0
                  stats[:bytes_received] += report_process[:bytes_received] || 0
                  stats[:bytes_sent] += report_process[:bytes_sent] || 0
                  stats[:listeners][:active] += report_process[:listeners][:active]
                  stats[:listeners][:standby] += report_process[:listeners][:standby]
                  stats[:processes] += 1
                  stats[:rss] += report_process[:memory_usage]
                  stats[:lag_hybrid] += lags_hybrid.compact.reject(&:negative?).sum
                  utilization += report_stats[:utilization]
                end

              stats[:utilization] = utilization / (stats[:processes] + 0.0001)
            end

            # @param report [Hash]
            # @param block [Proc]
            # @yieldparam partition_stats [Hash] statistics for a single partition
            # @yieldparam cg_id [Symbol] consumer group id this partition belongs to
            # @yieldparam topic_name [Symbol] topic name this partition belongs to
            # @yieldparam pt_id [Symbol] partition id (as reported, not normalized)
            def iterate_partitions(report, &block)
              report[:consumer_groups].each do |cg_id, consumer_group|
                consumer_group[:subscription_groups].each_value do |subscription_group|
                  subscription_group[:topics].each do |topic_name, topic|
                    topic[:partitions].each do |pt_id, partition_stats|
                      block.call(partition_stats, cg_id, topic_name, pt_id)
                    end
                  end
                end
              end
            end

            # Updates our own observation-based bookkeeping of how long each partition has been
            # continuously reported as paused. We cannot access any process-local pause
            # timestamp (that state lives in the reporting consumer process, not here), so
            # instead we record the report time the first moment we observe
            # `poll_state == "paused"` for a given partition, and clear it the moment we see it
            # active (or no longer reported at all) again.
            def track_paused_partitions
              currently_paused = {}

              @active_reports.each_value do |report|
                next if report[:process][:status] == "stopped"

                iterate_partitions(report) do |partition_stats, cg_id, topic_name, pt_id|
                  next unless partition_stats[:poll_state] == "paused"

                  key = [cg_id, topic_name, pt_id]
                  currently_paused[key] = true
                  @paused_since[key] ||= @aggregated_from
                end
              end

              @paused_since.keep_if { |key, _| currently_paused.key?(key) }
            end

            # Refreshes `state[:paused_partitions_lag]` with fresh cluster-side lag for
            # partitions that have been reported as paused for at least `min_pause_duration`,
            # throttled to run at most once every `refresh_interval`.
            #
            # A paused partition stops being actively fetched, so its self-reported
            # `lag`/`lag_stored` freeze at pause time while the real lag keeps growing. We
            # compensate by asking the cluster directly for a fresh high watermark and
            # combining it with the partition's own still-accurate self-reported
            # `committed_offset`/`stored_offset` (these do not go stale while paused - the
            # consumer genuinely has not processed anything new).
            #
            # @note We use `@aggregated_from` (report time) rather than wall-clock time so this
            #   stays consistent when catching up on a backlog of older reports.
            def refresh_paused_partitions_lag
              settings = ::Karafka::Web.config.processing.paused_partitions_lag

              if @paused_partitions_lag_refreshed_at &&
                  (@aggregated_from - @paused_partitions_lag_refreshed_at) <
                      (settings.refresh_interval / 1_000.0)
                return
              end

              @paused_partitions_lag_refreshed_at = @aggregated_from

              eligible = eligible_paused_partitions(settings.min_pause_duration / 1_000.0)

              if eligible.empty?
                state[:paused_partitions_lag] = {}
                return
              end

              fresh_offsets = fetch_fresh_watermarks(eligible, settings.query_timeout)

              # Graceful degradation: on any admin failure, leave the previous
              # state[:paused_partitions_lag] untouched rather than wiping it out - a
              # stale-but-recent correction is still better than none.
              return unless fresh_offsets

              state[:paused_partitions_lag] = build_paused_partitions_lag(eligible, fresh_offsets)
            end

            # @param min_pause_duration [Float] minimum time (in seconds) a partition must have
            #   been continuously paused before it is eligible for a cluster-side lag refresh
            # @return [Array<Hash>] one entry per eligible partition: `{ cg_id:, topic:,
            #   partition:, committed_offset:, stored_offset: }`
            def eligible_paused_partitions(min_pause_duration)
              eligible = []

              @active_reports.each_value do |report|
                next if report[:process][:status] == "stopped"

                iterate_partitions(report) do |partition_stats, cg_id, topic_name, pt_id|
                  next unless partition_stats[:poll_state] == "paused"

                  paused_since = @paused_since[[cg_id, topic_name, pt_id]]

                  next unless paused_since
                  next if (@aggregated_from - paused_since) < min_pause_duration

                  eligible << {
                    cg_id: cg_id.to_s,
                    topic: topic_name.to_s,
                    partition: pt_id.to_s.to_i,
                    committed_offset: partition_stats[:committed_offset],
                    stored_offset: partition_stats[:stored_offset]
                  }
                end
              end

              eligible
            end

            # @param eligible [Array<Hash>]
            # @param timeout [Integer] max time (in milliseconds) to allow the admin call to take
            # @return [Array<Hash>, nil] raw `read_partition_offsets` result, or `nil` on any
            #   failure (timeout, broker error, etc.)
            def fetch_fresh_watermarks(eligible, timeout)
              request = Hash.new { |hash, topic_name| hash[topic_name] = [] }

              eligible.each do |entry|
                request[entry[:topic]] << { partition: entry[:partition], offset: :latest }
              end

              request.each_value { |rows| rows.uniq! { |row| row[:partition] } }

              ::Karafka::Admin
                .new(kafka: { "admin.max.wait.ms": timeout })
                .read_partition_offsets(
                  request,
                  isolation_level: ::Karafka::Admin::IsolationLevels::READ_COMMITTED
                )
            rescue
              nil
            end

            # @param eligible [Array<Hash>]
            # @param fresh_offsets [Array<Hash>] raw `read_partition_offsets` result:
            #   `[{ topic:, partition:, offset:, timestamp:, leader_epoch: }, ...]`
            # @return [Hash] `{ cg_id => { topic => { partition_id => { lag:, lag_stored: } } } }`
            #   (string keys throughout)
            def build_paused_partitions_lag(eligible, fresh_offsets)
              watermarks = fresh_offsets.to_h { |row| [[row[:topic], row[:partition]], row[:offset]] }
              result = Hash.new { |hash, cg_id| hash[cg_id] = Hash.new { |h2, topic| h2[topic] = {} } }

              eligible.each do |entry|
                watermark = watermarks[[entry[:topic], entry[:partition]]]

                next unless watermark

                committed = entry[:committed_offset]
                stored = entry[:stored_offset]

                lag = (committed && committed >= 0) ? [watermark - committed, 0].max : nil
                lag_stored = (stored && stored >= 0) ? [watermark - stored, 0].max : nil

                next unless lag || lag_stored

                result[entry[:cg_id]][entry[:topic]][entry[:partition].to_s] = {
                  lag: lag,
                  lag_stored: lag_stored
                }.compact
              end

              result
            end
          end
        end
      end
    end
  end
end
