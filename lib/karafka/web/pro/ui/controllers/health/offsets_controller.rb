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
          module Health
            # Committed offsets of a consumer group for a topic. Deleting them makes a topic the
            # consumer group no longer consumes stop reporting cluster lags.
            class OffsetsController < BaseController
              # Renders a confirmation page for the offsets removal since it is a sensitive
              # operation
              #
              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              # @param subscribed [Boolean] true when Kafka rejected the deletion because the
              #   consumer group is subscribed to the topic
              # @param form_error [Rdkafka::RdkafkaError, Rdkafka::Config::ConfigError, nil] error
              #   of a failed deletion
              def edit(consumer_group_id, topic_name, subscribed: false, form_error: nil)
                bootstrap!(consumer_group_id, topic_name)

                @subscribed = subscribed
                @form_error = form_error

                render
              end

              # Deletes the committed offsets of the consumer group on all the topic partitions
              #
              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def delete(consumer_group_id, topic_name)
                bootstrap!(consumer_group_id, topic_name)

                begin
                  ::Karafka::Admin.delete_consumer_group_offsets(consumer_group_id, [topic_name])
                rescue ::Karafka::Errors::ConsumerGroupSubscribedToTopicError
                  return edit(consumer_group_id, topic_name, subscribed: true)
                rescue Rdkafka::RdkafkaError, Rdkafka::Config::ConfigError => e
                  return edit(consumer_group_id, topic_name, form_error: e)
                end

                redirect(
                  "health/cluster_lags",
                  success: format_flash(
                    "Offsets of consumer group ? for topic ? have been deleted",
                    consumer_group_id,
                    topic_name
                  )
                )
              end

              private

              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def bootstrap!(consumer_group_id, topic_name)
                policy = ::Karafka::Web.config.ui.policies.consumer_groups

                deny! unless policy.delete_offsets?(consumer_group_id, topic_name)

                @consumer_group_id = consumer_group_id
                @topic_name = topic_name

                # We query the topic directly, so topics hidden from the cluster lags (inactive or
                # not in the Web UI routing) can still be reached
                partitions = ::Karafka::Admin
                  .read_lags_with_offsets({ consumer_group_id => [topic_name] })
                  .dig(consumer_group_id, topic_name)

                not_found!(topic_name) if partitions.nil? || partitions.empty?

                @cluster_partitions = partitions.map do |partition_id, details|
                  { id: partition_id, lag: details.fetch(:lag), stored_offset: details.fetch(:offset) }
                end
              end
            end
          end
        end
      end
    end
  end
end
