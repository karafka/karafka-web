# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Moves to using lag total as a normalization for both lags
          class IntroduceLagTotal < Base
            self.versions_until = '1.3.0'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state[:stats][:lag_total] = state[:stats][:lag_stored]
              state[:stats].delete(:lag)
              state[:stats].delete(:lag_stored)
            end
          end
        end
      end
    end
  end
end
