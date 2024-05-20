# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Consumers metrics topic data related migrations
        module ConsumersMetrics
          # Initial migration that sets the consumers metrics initial first state.
          # This is the basic of metrics as they were when they were introduced.
          class SetInitial < Base
            # Always migrate from empty up
            self.versions_until = '0.0.1'
            self.type = :consumers_metrics

            # @param state [Hash] initial empty state
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
end
