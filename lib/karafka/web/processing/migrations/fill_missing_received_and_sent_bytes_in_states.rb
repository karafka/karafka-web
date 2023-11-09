# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Migrations
        class FillMissingReceivedAndSentBytesInStates < Base
          self.created_at = 1699543515
          self.versions_until = '1.1.0'
          self.type = :consumers_states

          def migrate(state)
            state[:stats][:bytes_sent] = 0
            state[:stats][:bytes_received] = 0

            state
          end
        end
      end
    end
  end
end
