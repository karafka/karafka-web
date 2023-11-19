# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Moves unused "processing" that was used instead of "busy" in older versions
        class RemoveProcessingFromConsumersState < Base
          self.versions_until = '1.2.1'
          self.type = :consumers_state

          # @param state [Hash]
          def migrate(state)
            state[:stats].delete(:processing)
          end
        end
      end
    end
  end
end
