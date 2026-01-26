# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the errors related routes
        class Errors < Base
          route do |r|
            r.on "errors" do
              controller = build(Controllers::ErrorsController)

              r.get Integer do |offset|
                if params.current_offset == -1
                  controller.show(offset)
                else
                  r.redirect root_path("errors", params.current_offset)
                end
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
