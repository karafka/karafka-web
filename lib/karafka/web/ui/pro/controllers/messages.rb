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
    module Ui
      module Pro
        module Controllers
          # Controller for working with messages
          # While part of messages operations is done via explorer (exploring), this controller
          # handles other cases not related to viewing data
          class Messages < Ui::Controllers::Base
            # Takes a requested message content and republishes it again
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer] offset of the message we want to republish
            def republish(topic_id, partition_id, offset)
              message = Ui::Models::Message.find(topic_id, partition_id, offset)

              delivery = ::Karafka::Web.producer.produce_sync(
                topic: topic_id,
                partition: partition_id,
                payload: message.raw_payload,
                headers: message.headers,
                key: message.key
              )

              redirect(
                :back,
                success: reproduced(message, delivery)
              )
            end

            private

            # @param message [Karafka::Messages::Message]
            # @param delivery [Rdkafka::Producer::DeliveryReport]
            # @return [String] flash message about message reproducing
            def reproduced(message, delivery)
              <<~MSG
                Message with offset #{message.offset}
                has been sent again to #{message.topic}##{message.partition}
                and received offset #{delivery.offset}.
              MSG
            end
          end
        end
      end
    end
  end
end
