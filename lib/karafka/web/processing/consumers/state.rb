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
                1
              ).last

              return state_message.payload if state_message

              raise(::Karafka::Web::Errors::Processing::MissingConsumersStateError)
            end
          end
        end
      end
    end
  end
end
