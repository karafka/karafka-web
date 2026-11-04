# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if the processing consumer recently rejected consumers reports.
            #
            # Reports are validated when they are ingested. A report that does not pass is not
            # materialized, so its process data is missing in the Web UI.
            class ConsumersReportsValidity < Base
              depends_on :consumers_reports_schema_state

              class << self
                # @return [Hash] default details when the check is halted
                def halted_details
                  { rejected: [] }
                end
              end

              # Executes the consumers reports validity check.
              #
              # @return [Status::Step] warning if reports were rejected recently, success otherwise
              def call
                rejected = context.current_state[:rejected_reports] || []

                step(rejected.empty? ? :success : :warning, { rejected: rejected })
              end
            end
          end
        end
      end
    end
  end
end
