# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the ux related routes
        class Ux < Base
          route do |r|
            r.get "ux" do
              controller = build(Controllers::UxController)
              controller.show
            end
          end
        end
      end
    end
  end
end
