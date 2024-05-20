# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Similar to filling in consumers metrics, we initialize this with zeros so it is always
          # present as expected
          class FillMissingReceivedAndSentBytes < Base
            # Network metrics were introduced with schema 1.2.0
            self.versions_until = '1.2.0'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state[:stats][:bytes_sent] = 0
              state[:stats][:bytes_received] = 0
            end
          end
        end
      end
    end
  end
end
