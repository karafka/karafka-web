# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Command to migrate states data
      # Useful when we have older schema and need to move forward
      class UpdateStatesData < Base
        # Runs needed migrations (if any) on the states topics
        def call
          Processing::Migrator.call
        end
      end
    end
  end
end
