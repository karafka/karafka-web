# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the dlq related routes
          class Dlq < Base
            route do |r|
              r.get 'dlq' do
                controller = Controllers::DlqController.new(params)
                controller.index
              end
            end
          end
        end
      end
    end
  end
end
