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

        route do |r|
          r.root { r.redirect root_path('dashboard') }

          # Serve current version specific assets to prevent users from fetching old assets
          # after upgrade
          r.on 'assets', Karafka::Web::VERSION do
            r.public
          end

          r.get 'dashboard' do
            @breadcrumbs = false
            controller = Controllers::Dashboard.new(params)
            controller.index
          end

          r.on 'consumers' do
            r.get String, 'subscriptions' do |_process_id|
              raise Errors::Ui::ProOnlyError
            end

            r.get do
              @breadcrumbs = false
              controller = Controllers::Consumers.new(params)
              controller.index
            end
          end

          %w[
            health
            explorer
            dlq
          ].each do |route|
            r.get route, [String, true], [String, true] do
              raise Errors::Ui::ProOnlyError
            end
          end

          r.on 'jobs' do
            r.get 'running' do
              controller = Controllers::Jobs.new(params)
              controller.running
            end

            r.redirect root_path('jobs/running')
          end

          r.on 'routing' do
            controller = Controllers::Routing.new(params)

            r.get String do |topic_id|
              controller.show(topic_id)
            end

            r.get do
              controller.index
            end
          end

          r.get 'cluster' do
            controller = Controllers::Cluster.new(params)
            controller.index
          end

          r.on 'errors' do
            controller = Controllers::Errors.new(params)

            r.get Integer do |offset|
              controller.show(offset)
            end

            r.get do
              controller.index
            end
          end

          r.get 'status' do
            controller = Controllers::Status.new(params)
            controller.show
          end
        end
      end
    end
  end
end
