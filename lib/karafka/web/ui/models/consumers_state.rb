# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Represents the current consumer processes aggregated state
        # This state is the core of Karafka reporting. It holds the most important aggregated data
        # as well as pointers to states of particular consumers and their details.
        class ConsumersState < Lib::HashProxy
          extend ::Karafka::Core::Helpers::Time

          class << self
            # @return [State, false] current aggregated state or false if not found
            # @note Current state may contain expired data, for example of processes that were
            #   forcefully killed, etc. We clean this prior to returning the state.
            def current
              state = fetch

              return false unless state
              # Do not return the state in case web-ui is not enabled because we need our
              # internal deserializer for it to operate. False will force user to go to the
              # status page
              return false unless Models::Status.new.enabled.success?

              state = state.payload
              evict_expired_processes(state)
              sort_processes(state)

              new(state)
            end

            # @return [State] current aggregated state
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError] raised when there is no current
            #   state.
            def current!
              current || raise(::Karafka::Web::Errors::Ui::NotFoundError)
            end

            private

            # @return [::Karafka::Messages::Message, nil] most recent state or nil if none
            def fetch
              Lib::Admin.read_topic(
                Karafka::Web.config.topics.consumers.states,
                0,
                # We need to take last two and not the last because in case of a transactional
                # producer, the last one will match the transaction commit message
                2
              ).last
            end

            # Evicts (removes) details about processes that are beyond our TTL on liveliness
            # @param state_hash [Hash] raw message state hash
            def evict_expired_processes(state_hash)
              max_ttl = ::Karafka::Web.config.ttl / 1_000

              state_hash[:processes].delete_if do |_, details|
                float_now - details[:dispatched_at] > max_ttl
              end
            end

            # Sorts the processes based on their unique ids, so they are always in order
            # @param state_hash [Hash] raw message state hash
            def sort_processes(state_hash)
              state_hash[:processes] = state_hash[:processes].to_a.sort_by(&:first).to_h
            end
          end
        end
      end
    end
  end
end
