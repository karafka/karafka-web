# frozen_string_literal: true

module Karafka
  module Web
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
