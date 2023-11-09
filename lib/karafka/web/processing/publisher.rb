# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Object responsible for publishing states data back into Kafka so it can be used in the UI
      class Publisher
        class << self
          # @param consumers_states [Hash] consumers current state
          # @param consumers_metrics [Hash] consumers current metrics
          def call(consumers_state, consumers_metrics)
            ::Karafka::Web.producer.produce_many_async(
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
            )
          end
        end
      end
    end
  end
end
