# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the errors related routes
        class Errors < Base
          route do |r|
            r.on 'errors' do
              controller = Controllers::ErrorsController.new(params)

              r.get Integer do |offset|
                controller.show(offset)
              end

              r.get do
                controller.index
              end
            end
          end
        end
      end
    end
  end
end
