# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Pro message reporting info controller
        class BecomePro < Base
          # Display a message, that a give feature is available only in Pro
          def show
            respond
          end
        end
      end
    end
  end
end
