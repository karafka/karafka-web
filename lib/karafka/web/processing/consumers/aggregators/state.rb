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
            SCHEMA_VERSION = '1.4.0'

            # @param schema_manager [Karafka::Web::Processing::Consumers::SchemaManager] schema
            #   manager that tracks the compatibility of schemas.
            def initialize(schema_manager)
              super()
              @schema_manager = schema_manager
            end

            # Uses provided process state report to update the current materialized state
            # @param report [Hash] consumer process state report
            # @param offset [Integer] offset of the message with the state report. This offset is
            #   needed as we need to be able to get all the consumers reports from a given offset.
            def add(report, offset)
              super(report)
              increment_total_counters(report)
              update_process_state(report, offset)
              # We always evict after counters updates because we want to use expired (stopped)
              # data for counters as it was valid previously. This can happen only when web consumer
              # had a lag and is catching up.
              evict_expired_processes
              # current means current in the context of processing window (usually now but in case
              # of lag, this state may be from the past)
              refresh_current_stats
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

            # Registers or updates the given process state based on the report
            #
            # @param report [Hash]
            # @param offset [Integer]
            def update_process_state(report, offset)
              process_id = report[:process][:id]

              state[:processes][process_id] = {
                dispatched_at: report[:dispatched_at],
                offset: offset
              }
            end

            # Evicts expired processes from the current state
            # We consider processes dead if they do not report often enough
            # @note We do not evict based on states (stopped), because we want to report the
            #   stopped processes for extra time within the ttl limitations. This makes tracking of
            #   things from UX perspective nicer.
            def evict_expired_processes
              max_ttl = @aggregated_from - ::Karafka::Web.config.ttl / 1_000

              state[:processes].delete_if do |_id, details|
                details[:dispatched_at] < max_ttl
              end

              @active_reports.delete_if do |_id, details|
                details[:dispatched_at] < max_ttl
              end
            end

            # Refreshes the counters that are computed based on incoming reports and not a total sum.
            # For this we use active reports we have in memory. It may not be accurate for the first
            # few seconds but it is much more optimal from performance perspective than computing
            # this fetching all data from Kafka for each view.
            def refresh_current_stats
              stats = state[:stats]

              stats[:busy] = 0
              stats[:enqueued] = 0
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
                .reject { |report| report[:process][:status] == 'stopped' }
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
            def iterate_partitions(report)
              report[:consumer_groups].each_value do |consumer_group|
                consumer_group[:subscription_groups].each_value do |subscription_group|
                  subscription_group[:topics].each_value do |topic|
                    topic[:partitions].each_value do |partition|
                      yield(partition)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
