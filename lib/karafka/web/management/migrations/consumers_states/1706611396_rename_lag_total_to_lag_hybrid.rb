# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Renames total lag to hybrid to better represent what it is
          class RenameLagTotalToLagHybrid < Base
            self.versions_until = '1.3.1'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state[:stats][:lag_hybrid] = state[:stats][:lag_total] || 0
              state[:stats].delete(:lag_total)
            end
          end
        end
      end
    end
  end
end
