# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the scheduled messages feature related routes
          class ScheduledMessages < Base
            route do |r|
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
            end
          end
        end
      end
    end
  end
end
