# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if we can read and operate on the current processes data.
            #
            # This verifies that the consumers reports can be parsed and loaded
            # into process objects for display in the UI.
            class ConsumersReports < Base
              depends_on :initial_consumers_metrics

              # Executes the consumers reports check.
              #
              # Attempts to load all processes from the current state. Caches
              # the result in context for subsequent checks.
              #
              # @return [Status::Step] result (success or failure on parse error)
              def call
                context.processes ||= Models::Processes.all(context.current_state)
                step(:success)
              rescue JSON::ParserError
                step(:failure)
              end
            end
          end
        end
      end
    end
  end
end
