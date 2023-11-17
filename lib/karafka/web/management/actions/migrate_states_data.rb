# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Command to migrate states data
        # Useful when we have older schema and need to move forward
        class MigrateStatesData < Base
          # Runs needed migrations (if any) on the states topics
          def call
            Migrator.new.call
          end
        end
      end
    end
  end
end
