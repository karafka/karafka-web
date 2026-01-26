# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the support related routes
        class Support < Base
          route do |r|
            r.get "support" do
              controller = build(Controllers::SupportController)
              controller.show
            end
          end
        end
      end
    end
  end
end
