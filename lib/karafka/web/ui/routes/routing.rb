# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the routing related routes
        class Routing < Base
          route do |r|
            r.on 'routing' do
              controller = build(Controllers::RoutingController)

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
