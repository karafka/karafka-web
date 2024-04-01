# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        module AlertsHelper
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
