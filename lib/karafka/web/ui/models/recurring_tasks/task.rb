# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module RecurringTasks
          # Represents a single recurring task
          class Task < Lib::HashProxy
            # @return [Boolean] true if this task is enabled, otherwise false
            def enabled?
              enabled
            end
          end
        end
      end
    end
  end
end
