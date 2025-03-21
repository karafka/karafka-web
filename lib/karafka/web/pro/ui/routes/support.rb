# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the support related routes
          class Support < Base
            route do |r|
              r.get 'support' do
                controller = build(Controllers::SupportController)
                controller.show
              end
            end
          end
        end
      end
    end
  end
end
