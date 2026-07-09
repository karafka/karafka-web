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

            # Ordered, unconditional pipeline of steps that enrich the shared `Context` on each
            # incoming report. Order here IS the contract: `RegisterProcess` runs before
            # `EvictExpiredProcesses` because we want to evict using expired (stopped) data as it
            # was valid previously (this can happen when the web consumer had a lag and is
            # catching up), `RefreshCurrentStats` runs after eviction because it recomputes the
            # snapshot from whatever is left in `active_reports`, and the paused-partitions steps
            # run last since they only need the same settled `active_reports`/`state` the earlier
            # steps already established.
            STEPS = [
              Steps::IncrementCounters,
              Steps::RegisterProcess,
              Steps::EvictExpiredProcesses,
              Steps::RefreshCurrentStats,
              Steps::TrackPausedPartitions,
              Steps::RefreshPausedPartitionsLag
            ].freeze

            # @param schema_manager [Karafka::Web::Processing::Consumers::SchemaManager] schema
            #   manager that tracks the compatibility of schemas.
            def initialize(schema_manager)
              super()
              @schema_manager = schema_manager
              # [cg_id, topic_name, partition_id] => @aggregated_from value when we first
              # observed that partition as paused. See Steps::TrackPausedPartitions.
              @paused_since = {}
              @paused_partitions_lag_refreshed_at = nil
            end

            # Uses provided process state report to update the current materialized state
            # @param report [Hash] consumer process state report
            # @param offset [Integer] offset of the message with the state report. This offset is
            #   needed as we need to be able to get all the consumers reports from a given offset.
            def add(report, offset)
              super(report)
              run_pipeline(report, offset)
            end

            # Registers or updates the given process state based on the report
            #
            # @param report [Hash]
            # @param offset [Integer]
            def add_state(report, offset)
              Steps::RegisterProcess.new(context(report, offset)).call
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

            # Builds a fresh, per-call context shared across pipeline steps.
            #
            # @param report [Hash]
            # @param offset [Integer]
            # @return [Context]
            def context(report, offset)
              Context.new(
                state: state,
                active_reports: @active_reports,
                aggregated_from: @aggregated_from,
                report: report,
                offset: offset,
                paused_since: @paused_since,
                paused_partitions_lag_refreshed_at: @paused_partitions_lag_refreshed_at
              )
            end

            # Runs the full pipeline of steps, enriching the shared context in order.
            #
            # @param report [Hash]
            # @param offset [Integer]
            def run_pipeline(report, offset)
              ctx = context(report, offset)

              STEPS.each { |step_class| step_class.new(ctx).call }

              # `paused_since` is a Hash, mutated in place by steps, so it stays in sync on its
              # own. `paused_partitions_lag_refreshed_at` is a scalar throttle timestamp that
              # steps reassign rather than mutate, so it needs to be written back explicitly.
              @paused_partitions_lag_refreshed_at = ctx.paused_partitions_lag_refreshed_at
            end
          end
        end
      end
    end
  end
end
