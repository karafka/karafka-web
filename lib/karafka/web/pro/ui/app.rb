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
              controller = Controllers::ConsumersController.new(params)

              r.get 'overview' do
                controller.index
              end

              r.get 'performance' do
                controller.performance
              end

              r.get 'controls' do
                controller.controls
              end

              r.on String, 'jobs' do |process_id|
                r.get 'running' do
                  controller.running_jobs(process_id)
                end

                r.get 'pending' do
                  controller.pending_jobs(process_id)
                end

                r.redirect root_path("consumers/#{process_id}/jobs/running")
              end

              r.get String, 'subscriptions' do |process_id|
                controller.subscriptions(process_id)
              end

              r.get String, 'details' do |process_id|
                controller.details(process_id)
              end

              r.redirect root_path('consumers/overview')
            end

            r.on 'commands' do
              controller = Controllers::CommandsController.new(params)

              r.on Integer do |offset_id|
                controller.show(offset_id)
              end

              r.get 'recent' do
                controller.recent
              end

              r.get do
                controller.index
              end
            end

            r.on 'commanding' do
              controller = Controllers::CommandingController.new(params)

              r.post 'quiet_all' do
                controller.quiet_all
              end

              r.post 'stop_all' do
                controller.stop_all
              end

              r.on String do |process_id|
                r.post 'trace' do
                  controller.trace(process_id)
                end

                r.post 'quiet' do
                  controller.quiet(process_id)
                end

                r.post 'stop' do
                  controller.stop(process_id)
                end
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

            r.on 'explorer' do
              r.get String, 'search' do |topic_id|
                # Search has it's own controller but we want to have this in the explorer routing
                # namespace because topic search is conceptually part of the explorer
                controller = Controllers::SearchController.new(params)
                controller.index(topic_id)
              end

              controller = Controllers::ExplorerController.new(params)

              r.get String, Integer, 'recent' do |topic_id, partition_id|
                controller.recent(topic_id, partition_id)
              end

              r.get String, Integer, Integer, 'surrounding' do |topic_id, partition_id, offset|
                controller.surrounding(topic_id, partition_id, offset)
              end

              r.get String, 'recent' do |topic_id|
                controller.recent(topic_id, nil)
              end

              # Jumps to offset matching the expected time
              r.get String, Integer, Time do |topic_id, partition_id, time|
                controller.closest(topic_id, partition_id, time)
              end

              r.get String, Integer, Integer do |topic_id, partition_id, offset|
                # If when viewing given message we get an offset of different message, we should
                # redirect there. This allows us to support pagination with the current engine
                if params.current_offset != -1
                  r.redirect explorer_path(topic_id, partition_id, params.current_offset)
                else
                  controller.show(topic_id, partition_id, offset)
                end
              end

              r.get String, Integer do |topic_id, partition_id|
                controller.partition(topic_id, partition_id)
              end

              r.get String do |topic_id|
                controller.topic(topic_id)
              end

              r.get do
                controller.index
              end
            end

            r.on 'messages' do
              controller = Controllers::MessagesController.new(params)

              r.post String, Integer, Integer, 'republish' do |topic_id, partition_id, offset|
                controller.republish(topic_id, partition_id, offset)
              end

              r.get String, Integer, Integer, 'download' do |topic_id, partition_id, offset|
                controller.download(topic_id, partition_id, offset)
              end

              r.get String, Integer, Integer, 'export' do |topic_id, partition_id, offset|
                controller.export(topic_id, partition_id, offset)
              end
            end

            r.on 'recurring_tasks' do
              controller = Controllers::RecurringTasksController.new(params)

              r.get 'schedule' do
                controller.schedule
              end

              r.get 'logs' do
                controller.logs
              end

              r.post 'trigger_all' do
                controller.trigger_all
              end

              r.post 'enable_all' do
                controller.enable_all
              end

              r.post 'disable_all' do
                controller.disable_all
              end

              r.post String, 'trigger' do |task_id|
                controller.trigger(task_id)
              end

              r.post String, 'enable' do |task_id|
                controller.enable(task_id)
              end

              r.post String, 'disable' do |task_id|
                controller.disable(task_id)
              end

              r.get do
                r.redirect root_path('recurring_tasks/schedule')
              end
            end

            r.on 'scheduled_messages' do
              r.on 'schedules' do
                controller = Controllers::ScheduledMessages::SchedulesController.new(params)

                r.get String do |topic_id|
                  controller.show(topic_id)
                end

                r.get do
                  controller.index
                end
              end

              r.on 'explorer' do
                controller = Controllers::ScheduledMessages::ExplorerController.new(params)

                r.get String do |topic_id|
                  controller.topic(topic_id)
                end

                r.get String, Integer do |topic_id, partition_id|
                  controller.partition(topic_id, partition_id)
                end

                # Jumps to offset matching the expected time
                r.get String, Integer, Time do |topic_id, partition_id, time|
                  controller.closest(topic_id, partition_id, time)
                end
              end

              r.on 'messages' do
                controller = Controllers::ScheduledMessages::MessagesController.new(params)

                r.post(
                  String, Integer, Integer, 'cancel'
                ) do |topic_id, partition_id, message_offset|
                  controller.cancel(topic_id, partition_id, message_offset)
                end
              end

              r.get do
                r.redirect root_path('scheduled_messages/schedules')
              end
            end

            r.on 'health' do
              controller = Controllers::HealthController.new(params)

              r.get 'lags' do
                controller.lags
              end

              r.get 'cluster_lags' do
                controller.cluster_lags
              end

              r.get 'offsets' do
                controller.offsets
              end

              r.get 'overview' do
                controller.overview
              end

              r.get 'changes' do
                controller.changes
              end

              r.get do
                r.redirect root_path('health/overview')
              end
            end

            r.on 'cluster' do
              controller = Controllers::ClusterController.new(params)

              r.get 'replication' do
                # We use the non-pro controller here because this action is the same
                controller = Ui::Controllers::ClusterController.new(params)
                controller.replication
              end

              r.get String do |broker_id|
                controller.show(broker_id)
              end

              r.get do
                controller.index
              end
            end

            r.on 'topics' do
              controller = Controllers::TopicsController.new(params)

              r.get String, 'config' do |topic_id|
                controller.config(topic_id)
              end

              r.get String, 'replication' do |topic_id|
                controller.replication(topic_id)
              end

              r.get String, 'distribution' do |topic_id|
                controller.distribution(topic_id)
              end

              r.get String, 'offsets' do |topic_id|
                controller.offsets(topic_id)
              end

              r.get String do |topic_id|
                r.redirect root_path('topics', topic_id, 'config')
              end

              r.get do
                controller.index
              end
            end

            r.on 'errors' do
              controller = Controllers::ErrorsController.new(params)

              r.get Integer, Integer do |partition_id, offset|
                if params.current_offset != -1
                  r.redirect root_path('errors', partition_id, params.current_offset)
                else
                  controller.show(partition_id, offset)
                end
              end

              r.get Integer do |partition_id|
                controller.partition(partition_id)
              end

              r.get do
                controller.index
              end
            end

            r.get 'dlq' do
              controller = Controllers::DlqController.new(params)
              controller.index
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
end
