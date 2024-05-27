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

          # @param message [String] alert message
          # @return [String] html with alert danger
          def alert_danger(message)
            partial(
              'shared/alerts/danger',
              locals: {
                message: message
              }
            )
          end

          # @param message [String] alert message
          # @return [String] html with alert warning
          def alert_warning(message)
            partial(
              'shared/alerts/warning',
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
