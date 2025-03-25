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
                  controller = build(Controllers::ScheduledMessages::SchedulesController)

                  r.get String do |topic_id|
                    controller.show(topic_id)
                  end

                  r.get do
                    controller.index
                  end
                end

                r.on 'explorer' do
                  r.on 'topics' do
                    controller = build(Controllers::ScheduledMessages::ExplorerController)

                    r.get String do |topic_id|
                      controller.topic(topic_id)
                    end

                    r.get String, :partition_id do |topic_id, partition_id|
                      controller.partition(topic_id, partition_id)
                    end

                    # Jumps to offset matching the expected time
                    r.get String, :partition_id, 'closest', Time do |topic_id, partition_id, time|
                      controller.closest(topic_id, partition_id, time)
                    end

                    # Jumps to the offset matching the expected timestamp
                    r.get(
                      String, :partition_id, 'closest', Integer
                    ) do |topic_id, partition_id, timestamp|
                      # To simplify we just convert timestamp to time with ms precision
                      time = Time.at(timestamp / 1_000.0)
                      controller.closest(topic_id, partition_id, time)
                    end
                  end
                end

                r.on 'messages' do
                  controller = build(Controllers::ScheduledMessages::MessagesController)

                  r.post(
                    String, :partition_id, Integer, 'cancel'
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
