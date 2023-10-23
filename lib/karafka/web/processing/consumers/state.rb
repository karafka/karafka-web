# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Fetches the current consumer processes aggregated state
        class State
          class << self
            # Fetch the current consumers state that is expected to exist
            #
            # @return [Hash] last (current) aggregated processes state
            def current!
              state_message = ::Karafka::Admin.read_topic(
                Karafka::Web.config.topics.consumers.states,
                0,
                # We need to take more in case there would be transactions running.
                # In theory we could take two but this compensates for any involuntary
                # revocations and cases where two producers would write to the same state
                5
              ).last

              return state_message.payload if state_message

              raise(::Karafka::Web::Errors::Processing::MissingConsumersStateError)
            rescue Rdkafka::RdkafkaError => e
              raise(e) unless e.code == :unknown_partition

              raise(::Karafka::Web::Errors::Processing::MissingConsumersStatesTopicError)
            end
          end
        end
      end
    end
  end
end
