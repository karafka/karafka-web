# frozen_string_literal: true

module Karafka
  module Web
    # Web UI namespace
    module Ui
      # Main Roda Web App that servers all the metrics and stats
      class App < Base
        # Use the gem views and assets location
        opts[:root] = Karafka::Web.gem_root.join('lib/karafka/web/ui')

        instance_exec(&CONTEXT_DETAILS)

        # Sub-routes for given pieces of the Web UI
        SUB_ROUTES = [
          Routes::Assets,
          Routes::Dashboard,
          Routes::Consumers,
          Routes::ProOnly,
          Routes::Jobs,
          Routes::Routing,
          Routes::Cluster,
          Routes::Errors,
          Routes::Status,
          Routes::Support,
          Routes::Ux
        ].freeze

        private_constant :SUB_ROUTES

        route do |r|
          r.root { r.redirect root_path('dashboard') }

          SUB_ROUTES.each { |sub_route| sub_route.bind(self, r) }
        end
      end
    end
  end
end
