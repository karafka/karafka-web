# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the topics related routes
          class Topics < Base
            route do |r|
              r.on 'topics' do
                r.get String, 'distribution' do |topic_id|
                  controller = Controllers::Topics::DistributionsController.new(params)
                  controller.show(topic_id)
                end

                r.get String, 'replication' do |topic_id|
                  controller = Controllers::Topics::ReplicationsController.new(params)
                  controller.show(topic_id)
                end

                r.get String, 'offsets' do |topic_id|
                  controller = Controllers::Topics::OffsetsController.new(params)
                  controller.show(topic_id)
                end

                r.get String, 'config' do |topic_id|
                  controller = Controllers::Topics::ConfigsController.new(params)
                  controller.show(topic_id)
                end

                r.get do
                  controller = Controllers::Topics::TopicsController.new(params)
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
