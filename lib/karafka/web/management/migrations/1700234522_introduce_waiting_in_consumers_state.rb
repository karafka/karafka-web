# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Introduce waiting in consumers metrics to complement busy and enqueued for jobs stats
        class IntroduceWaitingInConsumersState < Base
          self.versions_until = '1.2.1'
          self.type = :consumers_state

          # @param state [Hash]
          def migrate(state)
            state[:stats][:waiting] = 0
          end
        end
      end
    end
  end
end
