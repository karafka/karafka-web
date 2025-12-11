# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if there is at least one active Karafka server reporting to the Web UI.
            #
            # If no processes are reporting, the Web UI won't have any data to display.
            # This is a critical check for ensuring the system is actually being monitored.
            class LiveReporting < Base
              depends_on :consumers_reports

              # Executes the live reporting check.
              #
              # Verifies that there is at least one process in the list.
              #
              # @return [Status::Step] success if processes exist, failure if empty
              def call
                status = context.processes.empty? ? :failure : :success
                step(status)
              end
            end
          end
        end
      end
    end
  end
end
