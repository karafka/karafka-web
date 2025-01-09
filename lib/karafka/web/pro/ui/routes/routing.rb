# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the routing related routes
          class Routing < Base
            route do |r|
              r.on 'routing' do
                controller = Controllers::RoutingController.new(params)

                r.get String do |topic_id|
                  controller.show(topic_id)
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
end
