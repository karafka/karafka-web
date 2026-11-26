# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Registers or updates the given process state based on the report.
              #
              # @note Replayed reports are skipped, so the stored offset does not move back and
              #   the next replayed reports of the process are not counted again.
              class RegisterProcess < Base
                # Registers or updates `context.state[:processes]` for the reporting process
                def call
                  return if context.replayed?

                  # When we deserialize the keys from the stored state, because we convert keys
                  # into symbols, we may have given process state already stored. This means
                  # that in order to update it, we do need to have the new report process id
                  # also as a symbol to act as the key
                  process_id = context.report[:process][:id].to_sym

                  context.state[:processes][process_id] = {
                    dispatched_at: context.report[:dispatched_at],
                    offset: context.offset
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
