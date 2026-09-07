# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Explorer
            module Messages
              # Republishes existing messages to the same or a different topic.
              #
              # The form parsing, validation and transformation live in {Lib::Republishing}; this
              # controller only orchestrates them and handles the HTTP concerns.
              class RepublishingController < BaseController
                # Renders the form allowing for piping a message to a different topic
                #
                # @param topic_id [String]
                # @param partition_id [Integer]
                # @param offset [Integer] offset of the message we want to republish
                def forward(topic_id, partition_id, offset)
                  load_source_message(topic_id, partition_id, offset)

                  @topics = Models::ClusterInfo
                    .topics
                    .sort_by { |topic| topic[:topic_name] }

                  unless ::Karafka::Web.config.ui.visibility.internal_topics
                    @topics.reject! { |topic| topic[:topic_name].start_with?("__") }
                  end

                  # Default (initial) form state; on a failed submission `#republish` has already
                  # populated `@republish_form`/`@errors`, which the `||=` preserves.
                  @republish_form ||= {
                    target_topic: @topic_id,
                    target_partition: @partition_id.to_s,
                    include_source_headers: true,
                    skip_validation: false
                  }
                  @errors ||= {}

                  render
                end

                # Republishes the requested message to the target topic
                #
                # @param topic_id [String]
                # @param partition_id [Integer]
                # @param offset [Integer] offset of the message we want to republish
                def republish(topic_id, partition_id, offset)
                  @republish_form = Lib::Republishing::Normalizer.call(params)

                  load_source_message(topic_id, partition_id, offset)

                  # The contract answers "can this be republished safely?" - target topic exists,
                  # partition in range, and the payload is consumable by the target's deserializer.
                  @errors = Lib::Republishing::Contracts::Form.new.call(
                    @republish_form.merge(
                      target_partitions_count: target_partitions_count(@republish_form[:target_topic]),
                      source_message: @message
                    )
                  ).errors

                  # Re-render the form (preserving the entered values) with all errors at once
                  return forward(topic_id, partition_id, offset) unless @errors.empty?

                  delivery = Lib::Publishing::Dispatcher.new(
                    Lib::Republishing::Transform.call(@message, @republish_form)
                  ).call

                  # Land on the partition that received the copy so the user can see it, rather
                  # than going back to the source message
                  redirect(
                    "explorer/topics/#{delivery.topic}/#{delivery.partition}",
                    success: republished(@message, delivery)
                  )
                end

                private

                # Loads the source message and authorizes republishing it
                #
                # @param topic_id [String]
                # @param partition_id [Integer]
                # @param offset [Integer]
                def load_source_message(topic_id, partition_id, offset)
                  @message = Models::Message.find(topic_id, partition_id, offset)

                  deny! unless visibility_filter.republish?(@message)

                  @topic_id = topic_id
                  @partition_id = partition_id
                  @offset = offset
                end

                # @param target_topic [String] target topic name
                # @return [Integer, nil] the target topic's partition count, or nil when it is blank
                #   or does not exist
                def target_partitions_count(target_topic)
                  return nil if target_topic.empty?

                  Models::ClusterInfo.partitions_count(target_topic)
                rescue ::Karafka::Web::Errors::Ui::NotFoundError
                  nil
                end

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
              end
            end
          end
        end
      end
    end
  end
end
