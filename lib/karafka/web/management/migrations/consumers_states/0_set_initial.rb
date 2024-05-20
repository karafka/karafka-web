# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Consumers states topic data related migrations
        module ConsumersStates
          # Initial migration that sets the consumers state initial first state.
          # This is the basic of state as they were when they were introduced.
          class SetInitial < Base
            # Run this only on the first setup
            self.versions_until = '0.0.1'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state.merge!(
                processes: {},
                stats: {
                  batches: 0,
                  messages: 0,
                  retries: 0,
                  dead: 0,
                  busy: 0,
                  enqueued: 0,
                  processing: 0,
                  workers: 0,
                  processes: 0,
                  rss: 0,
                  listeners: 0,
                  utilization: 0,
                  errors: 0,
                  lag_stored: 0,
                  lag: 0
                },
                schema_state: 'accepted',
                dispatched_at: float_now
              )
            end
          end
        end
      end
    end
  end
end
