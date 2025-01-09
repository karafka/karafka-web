# frozen_string_literal: true

<<<<<<< HEAD
# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.
=======
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
>>>>>>> 1afda33fb7dc6e935eac73cb420f22c127068896

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
