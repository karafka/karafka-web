# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the dashboard related routes
          class Dashboard < Base
            route do |r|
              r.get 'dashboard' do
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
end
