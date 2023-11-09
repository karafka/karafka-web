# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        class SetInitialMetrics < Base
          self.versions_until = '0.0.1'
          self.type = :consumers_metrics

          def migrate(state)
            state.merge!(
              aggregated: {
                days: [],
                hours: [],
                minutes: [],
                seconds: []
              },
              consumer_groups: {
                days: [],
                hours: [],
                minutes: [],
                seconds: []
              },
              dispatched_at: float_now
            )
          end
        end
      end
    end
  end
end
