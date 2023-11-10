# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Creates the records needed for the Web-UI to operate.
        # It creates "almost" empty states because the rest is handled via migrations
        class CreateInitialStates < Base
          # Whole default empty state
          # This will be further migrated by the migrator
          DEFAULT_STATE = {
            schema_version: '0.0.0'
          }.freeze

          # Default metrics state
          DEFAULT_METRICS = {
            schema_version: '0.0.0'
          }.freeze

          # Creates the initial states for the Web-UI if needed (if they don't exist)
          def call
            if exists?(Karafka::Web.config.topics.consumers.states)
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

            if exists?(Karafka::Web.config.topics.consumers.metrics)
              exists('consumers metrics')
            else
              creating('consumers metrics')
              ::Karafka::Web.producer.produce_sync(
                topic: Karafka::Web.config.topics.consumers.metrics,
                key: Karafka::Web.config.topics.consumers.metrics,
                payload: DEFAULT_METRICS.to_json
              )
              created('consumers metrics')
            end
          end

          private

          # @param topic [String] topic name
          # @return [Boolean] true if there is already an initial record in a given topic
          def exists?(topic)
            !::Karafka::Admin.read_topic(topic, 0, 5).last.nil?
          end

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
end
