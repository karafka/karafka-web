# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Since we have introduced notion of pause listeners, we need to reflect this in the
          # UI, so the scaling changes are visible
          class SplitListenersIntoActiveAndPaused < Base
            self.versions_until = '1.2.2'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              listeners = if state[:stats].key?(:listeners)
                            state[:stats][:listeners].to_i
                          elsif state[:stats].key?(:listeners_count)
                            state[:stats][:listeners_count].to_i
                          else
                            0
                          end

              state[:stats][:listeners] = {
                active: listeners,
                standby: 0
              }
            end
          end
        end
      end
    end
  end
end
