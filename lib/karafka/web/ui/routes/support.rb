# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the support related routes
        class Support < Base
          route do |r|
            r.get 'support' do
              controller = Controllers::SupportController.new(params)
              controller.show
            end
          end
        end
      end
    end
  end
end
