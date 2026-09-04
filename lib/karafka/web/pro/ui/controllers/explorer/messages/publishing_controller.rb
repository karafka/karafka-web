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
              # Publishes brand new messages to a topic from the explorer.
              #
              # The form parsing, validation and transformation live in {Lib::Publishing}; this
              # controller only orchestrates them and handles the HTTP concerns.
              class PublishingController < BaseController
                # Renders the publish form for a given topic
                #
                # @param topic_id [String] topic to which we want to publish a message
                def build(topic_id)
                  @topic_id = topic_id

                  deny! unless visibility_filter.publish?(@topic_id)

                  # Ensures the topic exists (raises a not found otherwise) and gives the form the
                  # number of partitions to render the partition selector
                  @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

                  # Reads the (possibly empty) form state back so the view can render the fields.
                  # `@errors` is only defaulted here - when we re-render after a failed submission
                  # `#publish` has already populated it.
                  @publish_form = Lib::Publishing::Normalizer.call(params)
                  @errors ||= {}

                  render
                end

                # Publishes a brand new message with the user-provided content to the given topic
                #
                # @param topic_id [String] topic to which we want to publish a message
                def publish(topic_id)
                  @topic_id = topic_id

                  deny! unless visibility_filter.publish?(@topic_id)

                  @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

                  @publish_form = Lib::Publishing::Normalizer.call(params)

                  @errors = Lib::Publishing::Contracts::Form.new.call(
                    @publish_form.merge(partitions_count: @partitions_count)
                  ).errors

                  # Re-render the form (preserving the entered values) with all errors at once
                  return build(topic_id) unless @errors.empty?

                  delivery = Lib::Publishing::Dispatcher.new(
                    Lib::Publishing::Transform.call(topic_id, @publish_form)
                  ).call

                  # Land back on the topic we just published to so the user can see their message,
                  # regardless of where they navigated from
                  redirect(
                    "explorer/topics/#{topic_id}",
                    success: published(delivery)
                  )
                end

                private

                # @param delivery [Rdkafka::Producer::DeliveryReport]
                # @return [String] flash message about the published message
                #
                # @note We publish through the `acked` producer variant, so the delivery report
                #   always carries the assigned offset.
                def published(delivery)
                  format_flash(
                    "Message has been published to ?#? and received offset ?",
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
