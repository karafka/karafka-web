# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for the Roda app routing components
      module Routes
        # Base class for all sub-routes that we want to use
        # Splitting this makes the Roda app much smaller and allows us to operate within the scope
        # of one routing namespace easily
        class Base
          class << self
            # Stores the sub-routing
            #
            # @param block [Proc] routing block that we want to evaluate in roda
            def route(&block)
              @route_block = block
            end

            # Binds given routing block to Roda
            #
            # @param app [Karafka::Web::Ui::App] roda app
            # @param request [Karafka::Web::Ui::App::RodaRequest] roda request
            def bind(app, request)
              app.instance_exec(request, &@route_block)
            end
          end
        end
      end
    end
  end
end
