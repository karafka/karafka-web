# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the consumers related routes
          class Consumers < Base
            route do |r|
              r.on 'consumers' do
                controller = Controllers::Consumers::ConsumersController.new(params)

                r.get 'overview' do
                  controller.index
                end

                r.get String, 'subscriptions' do |process_id|
                  controller.subscriptions(process_id)
                end

                r.get String, 'details' do |process_id|
                  controller.details(process_id)
                end

                r.get 'performance' do
                  controller.performance
                end

                r.on String, 'partitions' do |process_id|
                  controller = Controllers::Consumers::Partitions::PausesController.new(params)

                  r.get(
                    String, String, :partition_id, 'pause', 'new'
                  ) do |subscription_group_id, topic, partition_id|
                    controller.new(process_id, subscription_group_id, topic, partition_id)
                  end

                  r.post(
                    String, String, :partition_id, 'pause'
                  ) do |subscription_group_id, topic, partition_id|
                    controller.create(process_id, subscription_group_id, topic, partition_id)
                  end

                  r.get(
                    String, String, :partition_id, 'pause', 'edit'
                  ) do |subscription_group_id, topic, partition_id|
                    controller.edit(process_id, subscription_group_id, topic, partition_id)
                  end

                  r.delete(
                    String, String, :partition_id, 'pause'
                  ) do |subscription_group_id, topic, partition_id|
                    controller.delete(process_id, subscription_group_id, topic, partition_id)
                  end

                  controller = Controllers::Consumers::Partitions::OffsetsController.new(params)

                  r.get(
                    String, String, :partition_id, 'offset', 'edit'
                  ) do |subscription_group_id, topic, partition_id|
                    controller.edit(process_id, subscription_group_id, topic, partition_id)
                  end

                  r.put(
                    String, String, :partition_id, 'offset'
                  ) do |subscription_group_id, topic, partition_id|
                    controller.update(process_id, subscription_group_id, topic, partition_id)
                  end
                end

                r.on String, 'jobs' do |process_id|
                  controller = Controllers::Consumers::JobsController.new(params)

                  r.get 'running' do
                    controller.running(process_id)
                  end

                  r.get 'pending' do
                    controller.pending(process_id)
                  end

                  r.redirect root_path("consumers/#{process_id}/jobs/running")
                end

                r.get 'controls' do
                  controller = Controllers::Consumers::ControlsController.new(params)

                  controller.index
                end

                r.on 'commands' do
                  controller = Controllers::Consumers::CommandsController.new(params)

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
                  controller = Controllers::Consumers::CommandingController.new(params)

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

                r.redirect root_path('consumers/overview')
              end
            end
          end
        end
      end
    end
  end
end
