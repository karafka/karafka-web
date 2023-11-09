# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Creates the records needed for the Web-UI to operate.
      class CreateInitialStates < Base
        # Defaults stats state that we create in Kafka
        DEFAULT_STATS = {
          batches: 0,
          messages: 0,
          retries: 0,
          dead: 0,
          busy: 0,
          enqueued: 0,
          processing: 0,
          workers: 0,
          processes: 0,
          rss: 0,
          listeners: 0,
          utilization: 0,
          errors: 0,
          lag_stored: 0,
          lag: 0
        }.freeze

        # Default empty historicals for first record in Kafka
        DEFAULT_AGGREGATED = Processing::TimeSeriesTracker::TIME_RANGES
                             .keys
                             .map { |range| [range, []] }
                             .to_h
                             .freeze

        # WHole default empty state (aside from dispatch time)
        DEFAULT_STATE = {
          processes: {},
          stats: DEFAULT_STATS,
          schema_state: 'accepted',
          schema_version: Processing::Consumers::Aggregators::State::SCHEMA_VERSION,
          dispatched_at: Time.now.to_f
        }.freeze

        # Default metrics state
        DEFAULT_METRICS = {
          aggregated: DEFAULT_AGGREGATED,
          consumer_groups: DEFAULT_AGGREGATED,
          dispatched_at: Time.now.to_f,
          schema_version: Processing::Consumers::Aggregators::Metrics::SCHEMA_VERSION
        }.freeze

        private_constant :DEFAULT_STATS, :DEFAULT_AGGREGATED

        # Creates the initial states for the Web-UI if needed (if they don't exist)
        def call
          p DEFAULT_STATE

          if Ui::Models::ConsumersState.current
            exists('consumers state')
          else
            creating('consumers state')
            ::Karafka::Web.producer.produce_sync(
              topic: Karafka::Web.config.topics.consumers.states,
              key: Karafka::Web.config.topics.consumers.states,
              payload: DEFAULT_STATE.to_json
            )
            created('consumers state')
          end

          if Ui::Models::ConsumersMetrics.current
            exists('consumers metrics')
          else
            creating('consumers metrics')
            ::Karafka::Web.producer.produce_sync(
              topic: Karafka::Web.config.topics.consumers.metrics,
              key: Karafka::Web.config.topics.consumers.metrics,
              payload: DEFAULT_METRICS.merge(dispatched_at: Time.now.to_f).to_json
            )
            created('consumers metrics')
          end
        end

        private

        # @param type [String] type of state
        # @return [String] exists message
        def exists(type)
          puts "Initial #{type} #{already} exists."
        end

        # @param type [String] type of state
        # @return [String] message that the state is being created
        def creating(type)
          puts "Creating #{type} initial record..."
        end

        # @param type [String] type of state
        # @return [String] message that the state was created
        def created(type)
          puts "Initial #{type} record #{successfully} created."
        end
      end
    end
  end
end
