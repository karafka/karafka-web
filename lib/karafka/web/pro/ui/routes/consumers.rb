# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the consumers related routes
          class Consumers < Base
            route do |r|
              r.on 'consumers' do
                controller = build(Controllers::Consumers::ConsumersController)

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

                r.on(
                  'partitions',
                  String,
                  String,
                  :partition_id
                ) do |consumer_group_id, topic, partition_id|
                  r.on 'pause' do
                    controller = build(Controllers::Consumers::Partitions::PausesController)

                    r.get 'new' do
                      controller.new(consumer_group_id, topic, partition_id)
                    end

                    r.post do
                      controller.create(consumer_group_id, topic, partition_id)
                    end

                    r.get 'edit' do
                      controller.edit(consumer_group_id, topic, partition_id)
                    end

                    r.delete do
                      controller.delete(consumer_group_id, topic, partition_id)
                    end
                  end

                  r.on 'offset' do
                    controller = build(Controllers::Consumers::Partitions::OffsetsController)

                    r.get 'edit' do
                      controller.edit(consumer_group_id, topic, partition_id)
                    end

                    r.put do
                      controller.update(consumer_group_id, topic, partition_id)
                    end
                  end
                end

                r.on 'topics', String, String, 'pause' do |cg_id, topic|
                  controller = build(Controllers::Consumers::Topics::PausesController)

                  r.get 'new' do
                    controller.new(cg_id, topic)
                  end

                  r.post do
                    controller.create(cg_id, topic)
                  end

                  r.get 'edit' do
                    controller.edit(cg_id, topic)
                  end

                  r.delete do
                    controller.delete(cg_id, topic)
                  end
                end

                r.on String, 'jobs' do |process_id|
                  controller = build(Controllers::Consumers::JobsController)

                  r.get 'running' do
                    controller.running(process_id)
                  end

                  r.get 'pending' do
                    controller.pending(process_id)
                  end

                  r.redirect consumers_path(process_id, 'jobs/running')
                end

                r.get 'controls' do
                  controller = build(Controllers::Consumers::ControlsController)

                  controller.index
                end

                r.on 'commands' do
                  controller = build(Controllers::Consumers::CommandsController)

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
                  controller = build(Controllers::Consumers::CommandingController)

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

                r.redirect consumers_path('overview')
              end
            end
          end
        end
      end
    end
  end
end
