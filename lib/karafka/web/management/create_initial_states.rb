# frozen_string_literal: true

module Karafka
  module Web
    module Management
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
          threads_count: 0,
          processes: 0,
          rss: 0,
          listeners_count: 0,
          utilization: 0,
          lag_stored: 0,
          errors: 0
        }.freeze

        # Default empty historicals for first record in Kafka
        DEFAULT_AGGREGATED = Processing::Consumers::TimeSeriesTracker::TIME_RANGES
                             .keys
                             .map { |range| [range, []] }
                             .to_h
                             .freeze

        # WHole default empty state (aside from dispatch time)
        DEFAULT_STATE = {
          processes: {},
          stats: DEFAULT_STATS
        }.freeze

        private_constant :DEFAULT_STATS, :DEFAULT_AGGREGATED, :DEFAULT_STATE

        # Creates the initial states for the Web-UI if needed (if they don't exist)
        def call
          if Ui::Models::ConsumersState.current
            exists('consumers state')
          else
            creating('consumers state')
            ::Karafka.producer.produce_sync(
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
            ::Karafka.producer.produce_sync(
              topic: Karafka::Web.config.topics.consumers.metrics,
              key: Karafka::Web.config.topics.consumers.metrics,
              payload: {
                aggregated: DEFAULT_AGGREGATED,
                consumer_groups: DEFAULT_AGGREGATED
              }.to_json
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
