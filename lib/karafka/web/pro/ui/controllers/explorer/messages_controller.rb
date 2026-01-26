# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
              # Renders a form allowing for piping a message to a different topic
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to republish
              def forward(topic_id, partition_id, offset)
                @message = Models::Message.find(topic_id, partition_id, offset)

                deny! unless visibility_filter.republish?(@message)

                @topic_id = topic_id
                @partition_id = partition_id
                @offset = offset

                @target_topic = @topic_id
                @target_partition = @partition_id

                @topics = Models::ClusterInfo
                  .topics
                  .sort_by { |topic| topic[:topic_name] }

                unless ::Karafka::Web.config.ui.visibility.internal_topics
                  @topics.reject! { |topic| topic[:topic_name].start_with?("__") }
                end

                render
              end

              # Takes a requested message content and republishes it again
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to republish
              def republish(topic_id, partition_id, offset)
                forward(topic_id, partition_id, offset)

                dispatch_message = {
                  topic: params.str(:target_topic),
                  payload: @message.raw_payload,
                  headers: @message.headers.dup,
                  key: @message.key
                }

                # Add target partition only if it was requested, otherwise it will use either the
                # message key (if present) or will jut round-robin
                unless params.fetch(:target_partition).empty?
                  dispatch_message[:partition] = params.int(:target_partition)
                end

                # Include source headers for enhanced debuggability
                if params.bool(:include_source_headers)
                  dispatch_message[:headers].merge!(
                    "source_topic" => @message.topic,
                    "source_partition" => @message.partition.to_s,
                    "source_offset" => @message.offset.to_s
                  )
                end

                delivery = ::Karafka::Web.producer.produce_sync(dispatch_message)

                redirect(
                  :previous,
                  success: republished(@message, delivery)
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
              def republished(message, delivery)
                format_flash(
                  "Message with offset ? has been sent to ?#? and received offset ?",
                  message.offset,
                  delivery.topic,
                  delivery.partition,
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
