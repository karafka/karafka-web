# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Pro message reporting info controller
        class BecomeProController < BaseController
          # Display a message, that a given feature is available only in Pro
          def show
            render
          end
        end
      end
    end
  end
end
