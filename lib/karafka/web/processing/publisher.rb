# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Object responsible for publishing states data back into Kafka so it can be used in the UI
      class Publisher
        class << self
          # Publishes data back to Kafka in an async fashion
          #
          # @param consumers_state [Hash] consumers current state
          # @param consumers_metrics [Hash] consumers current metrics
          def publish(consumers_state, consumers_metrics)
            ::Karafka::Web.producer.produce_many_async(
              prepare_data(consumers_state, consumers_metrics)
            )
          end

          # Publishes data back to Kafka in a sync fashion
          #
          # @param consumers_state [Hash] consumers current state
          # @param consumers_metrics [Hash] consumers current metrics
          def publish!(consumers_state, consumers_metrics)
            ::Karafka::Web.producer.produce_many_sync(
              prepare_data(consumers_state, consumers_metrics)
            )
          end

          private

          # Converts the states into format that we can dispatch to Kafka
          #
          # @param consumers_state [Hash] consumers current state
          # @param consumers_metrics [Hash] consumers current metrics
          # @return [Array<Hash>]
          def prepare_data(consumers_state, consumers_metrics)
            [
              {
                topic: Karafka::Web.config.topics.consumers.states,
                payload: Zlib::Deflate.deflate(consumers_state.to_json),
                # This will ensure that the consumer states are compacted
                key: Karafka::Web.config.topics.consumers.states,
                partition: 0,
                headers: { 'zlib' => 'true' }
              },
              {
                topic: Karafka::Web.config.topics.consumers.metrics,
                payload: Zlib::Deflate.deflate(consumers_metrics.to_json),
                key: Karafka::Web.config.topics.consumers.metrics,
                partition: 0,
                headers: { 'zlib' => 'true' }
              }
            ]
          end
        end
      end
    end
  end
end
