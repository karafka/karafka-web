# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the Kafka messages related routes
          class Messages < Base
            route do |r|
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
            end
          end
        end
      end
    end
  end
end
