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
    module Ui
      # Pro Web UI components
      module Pro
        # Main Roda Web App that servers all the metrics and stats
        class App < Ui::Base
          opts[:root] = Karafka::Web.gem_root.join('lib/karafka/web/ui/pro')

          instance_exec(&CONTEXT_DETAILS)

          plugin :render, escape: true, engine: 'erb', allowed_paths: [
            Karafka::Web.gem_root.join('lib/karafka/web/ui/pro/views'),
            Karafka::Web.gem_root.join('lib/karafka/web/ui/views')
          ]

          plugin :additional_view_directories, [
            Karafka::Web.gem_root.join('lib/karafka/web/ui/views')
          ]

          route do |r|
            r.root { r.redirect root_path('dashboard') }

            # Serve current version specific assets to prevent users from fetching old assets
            # after upgrade
            r.on(:assets, Karafka::Web::VERSION) do
              r.public
            end

            r.get 'dashboard' do
              @breadcrumbs = false
              controller = Controllers::Dashboard.new(params)
              controller.index
            end

            r.on 'consumers' do
              controller = Controllers::Consumers.new(params)

              r.get String, 'jobs' do |process_id|
                controller.jobs(process_id)
              end

              r.get String, 'subscriptions' do |process_id|
                controller.subscriptions(process_id)
              end

              r.get String, 'details' do |process_id|
                controller.details(process_id)
              end

              r.get do
                @breadcrumbs = false
                controller.index
              end
            end

            r.get 'jobs' do
              controller = Controllers::Jobs.new(params)
              controller.index
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

            r.on 'explorer' do
              controller = Controllers::Explorer.new(params)

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
              controller = Controllers::Messages.new(params)

              r.post String, Integer, Integer, 'republish' do |topic_id, partition_id, offset|
                controller.republish(topic_id, partition_id, offset)
              end
            end

            r.on 'health' do
              controller = Controllers::Health.new(params)

              r.get 'offsets' do
                controller.offsets
              end

              r.get 'overview' do
                controller.overview
              end

              r.get do
                r.redirect root_path('health/overview')
              end
            end

            r.get 'cluster' do
              controller = Controllers::Cluster.new(params)
              controller.index
            end

            r.on 'errors' do
              controller = Controllers::Errors.new(params)

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
              controller = Controllers::Dlq.new(params)
              controller.index
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
end
