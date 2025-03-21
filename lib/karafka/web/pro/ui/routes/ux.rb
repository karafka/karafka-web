# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the UX controller routes
          class Ux < Base
            route do |r|
              r.get 'ux' do
                controller = build(Controllers::UxController)
                controller.show
              end
            end
          end
        end
      end
    end
  end
end
