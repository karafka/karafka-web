# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    # Namespace for all the pro components of the Web UI
    module Pro
      # Pro Web UI components
      module Ui
        # Main Roda Web App that servers all the metrics and stats
        class App < Web::Ui::Base
          opts[:root] = Karafka::Web.gem_root.join('lib/karafka/web/pro/ui')

          instance_exec(&CONTEXT_DETAILS)

          plugin :render, escape: true, engine: 'erb', allowed_paths: [
            Karafka::Web.gem_root.join('lib/karafka/web/pro/ui/views'),
            Karafka::Web.gem_root.join('lib/karafka/web/ui/views')
          ]

          plugin :additional_view_directories, [
            Karafka::Web.gem_root.join('lib/karafka/web/ui/views')
          ]

          before do
            assets_path = root_path("assets/#{Karafka::Web::VERSION}/")

            # Always allow assets
            break true if request.path.start_with?(assets_path)
            # If policies extension is not loaded, allow as this is the default
            break true unless Web.config.ui.respond_to?(:policies)
            break true if Web.config.ui.policies.requests.allow?(env)

            # Do not allow if given request violates requests policies
            raise(Errors::Ui::ForbiddenError)
          end

          # Sub-routes for given pieces of the Web UI
          SUB_ROUTES = [
            # Asset handling is exactly the same in both cases
            ::Karafka::Web::Ui::Routes::Assets,
            Routes::Dashboard,
            Routes::Consumers,
            Routes::Jobs,
            Routes::Routing,
            Routes::Explorer,
            Routes::RecurringTasks,
            Routes::ScheduledMessages,
            Routes::Health,
            Routes::Cluster,
            Routes::Topics,
            Routes::Errors,
            Routes::Dlq,
            Routes::Status,
            Routes::Support,
            Routes::Ux
          ].freeze

          private_constant :SUB_ROUTES

          route do |r|
            r.root { r.redirect root_path('dashboard') }

            SUB_ROUTES.each { |sub_route| sub_route.bind(self, r) }

            nil
          end

          # @return [Karafka::Web::Pro::Ui::Lib::Features] features fetcher
          def features
            Lib::Features
          end
        end
      end
    end
  end
end
