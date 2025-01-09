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
