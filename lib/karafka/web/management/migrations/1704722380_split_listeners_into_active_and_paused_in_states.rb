# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Since we have introduced notion of pause listeners, we need to reflect this in the
        # UI, so the scaling changes are visible
        class SplitListenersIntoActiveAndPausedInStates < Base
          self.versions_until = '1.2.2'
          self.type = :consumers_state

          # @param state [Hash]
          def migrate(state)
            listeners = state[:stats][:listeners].to_i

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
