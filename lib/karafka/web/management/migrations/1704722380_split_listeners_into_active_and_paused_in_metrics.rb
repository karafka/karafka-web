# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Since we have introduced notion of pause listeners, we need to reflect this in the
        # UI, so the scaling changes are visible
        class SplitListenersIntoActiveAndPausedInMetrics < Base
          self.versions_until = '1.1.2'
          self.type = :consumers_metrics

          # @param state [Hash]
          def migrate(state)
            state[:aggregated].each_value do |metrics|
              metrics.each do |metric|
                listeners = metric.last[:listeners].to_i

                metric.last[:listeners] = {
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
end
