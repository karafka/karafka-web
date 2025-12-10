# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if any consumer processes have incompatible schemas.
            #
            # Schema compatibility is important for proper data deserialization.
            # This check identifies processes that don't match the expected schema
            # version used by the Web UI.
            #
            # @note This is a warning-only check - incompatible schemas don't block
            #   the dependency chain but should be addressed.
            class ConsumersSchemas < Base
              depends_on :consumers_reports

              class << self
                # @return [Hash] details with empty incompatible list for halted state
                def halted_details
                  { incompatible: [] }
                end
              end

              # Executes the consumers schemas check.
              #
              # Identifies processes with incompatible schema versions.
              #
              # @return [Status::Step] success if all compatible, warning if any incompatible
              def call
                incompatible = context.processes.reject(&:schema_compatible?)
                status = incompatible.empty? ? :success : :warning

                step(status, { incompatible: incompatible })
              end
            end
          end
        end
      end
    end
  end
end
