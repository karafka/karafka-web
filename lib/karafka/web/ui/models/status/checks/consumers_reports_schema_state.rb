# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if the consumer can digest the consumers reports with its schema.
            #
            # The schema_state in the current state indicates whether the consumer
            # processing reports can properly deserialize them. If incompatible,
            # data may be lost or corrupted.
            class ConsumersReportsSchemaState < Base
              depends_on :state_calculation

              # Executes the consumers reports schema state check.
              #
              # Verifies that the schema_state is 'compatible'.
              #
              # @return [Status::Step] success if compatible, failure otherwise
              def call
                compatible = context.current_state[:schema_state] == 'compatible'
                step(compatible ? :success : :failure)
              end
            end
          end
        end
      end
    end
  end
end
