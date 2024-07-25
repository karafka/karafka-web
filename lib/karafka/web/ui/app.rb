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
            controller = Controllers::DashboardController.new(params)
            controller.index
          end

          r.on 'consumers' do
            %w[
              performance
              controls
              commands
            ].each do |path|
              r.get path do |_process_id|
                raise Errors::Ui::ProOnlyError
              end
            end

            r.get String, 'subscriptions' do |_process_id|
              raise Errors::Ui::ProOnlyError
            end

            r.get do
              controller = Controllers::ConsumersController.new(params)
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
            controller = Controllers::JobsController.new(params)

            r.get 'running' do
              controller.running
            end

            r.get 'pending' do
              controller.pending
            end

            r.redirect root_path('jobs/running')
          end

          r.on 'routing' do
            controller = Controllers::RoutingController.new(params)

            r.get String do |topic_id|
              controller.show(topic_id)
            end

            r.get do
              controller.index
            end
          end

          r.on 'cluster' do
            controller = Controllers::ClusterController.new(params)

            r.get 'brokers' do
              controller.brokers
            end

            r.get 'replication' do
              controller.replication
            end

            r.redirect root_path('cluster/brokers')
          end

          r.on 'topics' do
            raise Errors::Ui::ProOnlyError
          end

          r.on 'errors' do
            controller = Controllers::ErrorsController.new(params)

            r.get Integer do |offset|
              controller.show(offset)
            end

            r.get do
              controller.index
            end
          end

          r.get 'status' do
            controller = Controllers::StatusController.new(params)
            controller.show
          end

          r.get 'ux' do
            controller = Controllers::UxController.new(params)
            controller.show
          end

          r.get 'support' do
            controller = Controllers::SupportController.new(params)
            controller.show
          end
        end
      end
    end
  end
end
