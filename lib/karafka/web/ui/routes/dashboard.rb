# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the dashboard related routes
        class Dashboard < Base
          route do |r|
            r.get "dashboard" do
              @breadcrumbs = false
              controller = build(Controllers::DashboardController)
              controller.index
            end
          end
        end
      end
    end
  end
end
