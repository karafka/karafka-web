# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Fetches the current consumers historical metrics data
        class Metrics
          class << self
            # Fetch the current metrics data that is expected to exist
            #
            # @return [Hash] latest (current) aggregated metrics state
            def current!
              metrics_message = ::Karafka::Admin.read_topic(
                Karafka::Web.config.topics.consumers.metrics,
                0,
                # We need to take more in case there would be transactions running.
                # In theory we could take two but this compensates for any involuntary
                # revocations and cases where two producers would write to the same state
                5
              ).last

              return metrics_message.payload if metrics_message

              raise(::Karafka::Web::Errors::Processing::MissingConsumersMetricsError)
            rescue Rdkafka::RdkafkaError => e
              raise(e) unless e.code == :unknown_partition

              raise(::Karafka::Web::Errors::Processing::MissingConsumersMetricsTopicError)
            end
          end
        end
      end
    end
  end
end
