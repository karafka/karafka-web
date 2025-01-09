# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module ScheduledMessages
            # Provides management of schedules related messages
            class MessagesController < BaseController
              # Generates a cancel request for a given schedule message
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param message_offset [Integer]
              def cancel(topic_id, partition_id, message_offset)
                # Fetches the message we want to cancel to get its key
                scheduled_message = Karafka::Admin.read_topic(
                  topic_id,
                  partition_id,
                  1,
                  message_offset
                ).first

                cancel_message = ::Karafka::Pro::ScheduledMessages.cancel(
                  key: scheduled_message.key,
                  envelope: {
                    topic: topic_id,
                    partition: partition_id
                  }
                )

                Karafka::Web.producer.produce_sync(cancel_message)

                redirect(
                  :back,
                  success: <<~MESSAGE
                    A scheduled message with offset #{message_offset}
                    from #{topic_id} partition #{partition_id}
                    had a cancel request message successfully created.
                  MESSAGE
                )
              end
            end
          end
        end
      end
    end
  end
end
