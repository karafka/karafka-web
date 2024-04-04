# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helper for generating general alerts
        module AlertsHelper
          # @param message [String] alert message
          # @return [String] html with alert info
          def alert_info(message)
            partial(
              'shared/alerts/info',
              locals: {
                message: message
              }
            )
          end
        end
      end
    end
  end
end
