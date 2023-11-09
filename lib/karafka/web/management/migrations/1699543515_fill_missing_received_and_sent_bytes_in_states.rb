# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        class FillMissingReceivedAndSentBytesInStates < Base
          self.versions_until = '1.1.0'
          self.type = :consumers_state

          def migrate(state)
            state[:stats][:bytes_sent] = 0
            state[:stats][:bytes_received] = 0
          end
        end
      end
    end
  end
end
