# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Introduce waiting in consumers metrics to complement busy and enqueued for jobs stats
          class IntroduceWaiting < Base
            self.versions_until = '1.2.1'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state[:stats][:waiting] = 0
            end
          end
        end
      end
    end
  end
end
