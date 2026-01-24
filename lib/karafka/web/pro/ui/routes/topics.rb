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
          # Manages the topics related routes
          class Topics < Base
            route do |r|
              r.on 'topics' do
                r.on String, 'distribution' do |topic_id|
                  controller = build(Controllers::Topics::DistributionsController)

                  r.get 'edit' do
                    controller.edit(topic_id)
                  end

                  r.put do
                    controller.update(topic_id)
                  end

                  r.get do
                    controller.show(topic_id)
                  end
                end

                r.get String, 'replication' do |topic_id|
                  controller = build(Controllers::Topics::ReplicationsController)
                  controller.show(topic_id)
                end

                r.get String, 'offsets' do |topic_id|
                  controller = build(Controllers::Topics::OffsetsController)
                  controller.show(topic_id)
                end

                r.on String, 'config' do |topic_id|
                  controller = build(Controllers::Topics::ConfigsController)

                  r.get String, 'edit' do |property_name|
                    controller.edit(topic_id, property_name)
                  end

                  r.put String do |property_name|
                    controller.update(topic_id, property_name)
                  end

                  r.get do
                    controller.index(topic_id)
                  end
                end

                controller = build(Controllers::Topics::TopicsController)

                r.get 'new' do
                  controller.new
                end

                r.post do
                  controller.create
                end

                # Topic removal confirmation page since it's a sensitive operation
                r.get String, 'delete' do |topic_id|
                  controller.edit(topic_id)
                end

                r.delete String do |topic_id|
                  controller.delete(topic_id)
                end

                r.get do
                  controller.index
                end

                r.get String do |topic_id|
                  r.redirect root_path('topics', topic_id, 'config')
                end
              end
            end
          end
        end
      end
    end
  end
end
