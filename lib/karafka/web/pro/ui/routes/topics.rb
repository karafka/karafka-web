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
            end
          end
        end
      end
    end
  end
end
