# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the status related routes
          class Status < Base
            route do |r|
              r.get 'status' do
                controller = Controllers::StatusController.new(params)
                controller.show
              end
            end
          end
        end
      end
    end
  end
end
