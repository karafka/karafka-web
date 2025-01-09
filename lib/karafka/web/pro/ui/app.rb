# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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

          route do |r|
            r.root { r.redirect root_path('dashboard') }

            Routes::Assets.bind(self, r)
            Routes::Dashboard.bind(self, r)
            Routes::Consumers.bind(self, r)
            Routes::Jobs.bind(self, r)
            Routes::Routing.bind(self, r)
            Routes::Explorer.bind(self, r)
            Routes::Messages.bind(self, r)
            Routes::RecurringTasks.bind(self, r)
            Routes::ScheduledMessages.bind(self, r)
            Routes::Health.bind(self, r)
            Routes::Cluster.bind(self, r)
            Routes::Topics.bind(self, r)
            Routes::Errors.bind(self, r)
            Routes::Dlq.bind(self, r)
            Routes::Status.bind(self, r)
            Routes::Support.bind(self, r)
            Routes::Ux.bind(self, r)
          end
        end
      end
    end
  end
end
