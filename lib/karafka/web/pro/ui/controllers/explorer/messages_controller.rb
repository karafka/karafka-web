# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Explorer
            # Controller for working with messages
            # While part of messages operations is done via explorer (exploring), this controller
            # handles other cases not related to viewing data
            class MessagesController < BaseController
              # Takes a requested message content and republishes it again
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to republish
              def republish(topic_id, partition_id, offset)
                message = Models::Message.find(topic_id, partition_id, offset)

                deny! unless visibility_filter.republish?(message)

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

              # Dispatches the message raw payload to the browser as a file
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to download
              def download(topic_id, partition_id, offset)
                message = Models::Message.find(topic_id, partition_id, offset)

                deny! unless visibility_filter.download?(message)

                file(
                  message.raw_payload,
                  "#{topic_id}_#{partition_id}_#{offset}_payload.msg"
                )
              end

              # Dispatches the message payload first deserialized and then serialized to JSON
              # It differs from the raw payload in cases where raw payload is compressed or binary
              # or contains data that the Web UI user should not see that was altered on the Web UI
              # with the visibility filter.
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to export
              def export(topic_id, partition_id, offset)
                Lib::PatternsDetector.new.call

                message = Models::Message.find(topic_id, partition_id, offset)

                # Check if exports are allowed
                deny! unless visibility_filter.export?(message)

                file(
                  message.payload.to_json,
                  "#{topic_id}_#{partition_id}_#{offset}_payload.json"
                )
              end

              private

              # @param message [Karafka::Messages::Message]
              # @param delivery [Rdkafka::Producer::DeliveryReport]
              # @return [String] flash message about message reproducing
              def reproduced(message, delivery)
                format_flash(
                  'Message with offset ? has been sent again to ?#? and received offset ?',
                  message.offset,
                  message.topic,
                  message.partition,
                  delivery.offset
                )
              end

              # @return [Object] visibility filter. Either default or user-based
              def visibility_filter
                ::Karafka::Web.config.ui.policies.messages
              end
            end
          end
        end
      end
    end
  end
end
