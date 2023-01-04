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
            r.root { r.redirect root_path('consumers') }

            @current_page = params.current_page

            r.on 'consumers' do
              controller = Controllers::Consumers.new(params)

              r.get String, 'jobs' do |process_id|
                render_response controller.jobs(process_id)
              end

              r.get String, 'subscriptions' do |process_id|
                render_response controller.subscriptions(process_id)
              end

              r.get do
                @breadcrumbs = false
                render_response controller.index
              end
            end

            r.get 'jobs' do
              controller = Controllers::Jobs.new(params)
              render_response controller.index
            end

            r.on 'routing' do
              controller = Controllers::Routing.new(params)

              r.get String do |topic_id|
                render_response controller.show(topic_id)
              end

              r.get do
                render_response controller.index
              end
            end

            r.on 'explorer' do
              controller = Controllers::Explorer.new(params)

              r.get String, Integer, Integer do |topic_id, partition_id, offset|
                render_response controller.show(topic_id, partition_id, offset)
              end

              r.get String, Integer do |topic_id, partition_id|
                render_response controller.partition(topic_id, partition_id)
              end

              r.get do
                render_response controller.index
              end
            end

            r.get 'health' do
              controller = Controllers::Health.new(params)
              render_response controller.index
            end

            r.get 'cluster' do
              controller = Controllers::Cluster.new(params)
              render_response controller.index
            end

            r.on 'errors' do
              controller = Controllers::Errors.new(params)

              r.get Integer do |partition_id|
                render_response controller.index(partition_id)
              end

              r.get Integer, Integer do |partition_id, offset|
                render_response controller.show(partition_id, offset)
              end
            end

            r.get 'dlq' do
              controller = Controllers::Dlq.new(params)
              render_response controller.index
            end
          end
        end
      end
    end
  end
end
