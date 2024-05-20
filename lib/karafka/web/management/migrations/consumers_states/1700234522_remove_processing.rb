# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Moves unused "processing" that was used instead of "busy" in older versions
          class RemoveProcessing < Base
            self.versions_until = '1.2.1'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state[:stats].delete(:processing)
            end
          end
        end
      end
    end
  end
end
