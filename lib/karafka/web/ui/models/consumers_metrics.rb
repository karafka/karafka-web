# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Model representing the current consumers metrics most recent state
        class ConsumersMetrics < Lib::HashProxy
          class << self
            # @return [State, false] current consumers metrics or false if not found
            def current
              state = fetch

              return false unless state

              # Do not return the state in case web-ui is not enabled because we need our
              # internal deserializer for it to operate. False will force user to go to the
              # status page
              return false unless Models::Status.new.enabled.success?

              state = state.payload
              new(state)
            end

            # @return [State] current consumers metrics
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError] raised when there is no metrics.
            def current!
              current || raise(::Karafka::Web::Errors::Ui::NotFoundError)
            end

            private

            # @return [::Karafka::Messages::Message, nil] most recent state or nil if none
            def fetch
              Lib::Admin.read_topic(
                Karafka::Web.config.topics.consumers.metrics,
                0,
                # We need to take last two and not the last because in case of a transactional
                # producer, the last one will match the transaction commit message
                2
              ).last
            end
          end
        end
      end
    end
  end
end
