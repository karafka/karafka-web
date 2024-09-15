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
