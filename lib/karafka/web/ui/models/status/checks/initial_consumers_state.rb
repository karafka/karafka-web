# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if the initial consumers state is present and can be deserialized.
            #
            # The consumers state topic must contain valid data that can be parsed.
            # This check fetches the current state and attempts to deserialize it.
            class InitialConsumersState < Base
              depends_on :replication

              class << self
                # @return [Hash] details indicating presence issue for halted state
                def halted_details
                  { issue_type: :presence }
                end
              end

              # Executes the initial consumers state check.
              #
              # Fetches the current consumers state from Kafka and verifies it can
              # be deserialized. Caches the result in context for subsequent checks.
              #
              # @return [Status::Step] result with issue_type in details
              def call
                details = { issue_type: :presence }

                begin
                  context.current_state ||= Models::ConsumersState.current
                  status = context.current_state ? :success : :failure
                rescue JSON::ParserError
                  status = :failure
                  details[:issue_type] = :deserialization
                end

                step(status, details)
              end
            end
          end
        end
      end
    end
  end
end
