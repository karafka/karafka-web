# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Fetches the current consumer processes aggregated state
        class State
          extend ::Karafka::Core::Helpers::Time

          class << self
            # Try bootstrapping from the current state from Kafka if exists and if not, just use
            # a blank state. Blank state will not be flushed because materialization into Kafka
            # happens only after first report is received.
            #
            # @return [Hash, false] last (current) aggregated processes state or false if no
            #   state is available
            def current
              state_message = ::Karafka::Admin.read_topic(
                Karafka::Web.config.topics.consumers.states,
                0,
                1
              ).last

              state_message ? state_message.payload : { processes: {}, stats: {}, historicals: {} }
            end
          end
        end
      end
    end
  end
end
