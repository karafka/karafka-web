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
      module Mcp
        module Tools
          # Deletes the committed offsets of a consumer group for a topic, as the Web UI Delete
          # Offsets action
          class DeleteConsumerGroupOffsets < Base
            tool(
              "karafka_delete_consumer_group_offsets",
              <<~TEXT.tr("\n", " ").strip,
                Deletes the committed offsets of a consumer group for one topic, as the Web UI
                Delete Offsets action does. The group then starts from its initial offset. Kafka
                refuses it while the group consumes the topic. It cannot be undone.
              TEXT
              contract: Contracts::ConsumerGroupTopic.new,
              operation: :reset_offsets,
              destructive: true,
              idempotent: true,
              properties: {
                consumer_group_id: { type: "string", description: "Id of the consumer group" },
                topic: { type: "string", description: "Topic of the offsets to delete" }
              },
              required: %w[consumer_group_id topic]
            )

            # The consumer groups policy must allow it, as for the Web UI action
            def authorize!
              policy = ::Karafka::Web.config.ui.policies.consumer_groups

              return if policy.delete_offsets?(consumer_group_id, topic)

              deny!("The consumer groups policy denies deleting these offsets")
            end

            # @return [Array<String>] the topic of the deleted offsets
            def topics
              [topic]
            end

            private

            # @return [Hash] deleted offsets
            def fetch
              change = plan

              begin
                ::Karafka::Admin.delete_consumer_group_offsets(consumer_group_id, [topic])
              rescue ::Karafka::Errors::ConsumerGroupSubscribedToTopicError
                raise Errors::Mcp::NoDataError, "Consumer group #{consumer_group_id} consumes " \
                  "#{topic}: stop its consumers first"
              end

              { deleted: true }.merge(change)
            end

            # @return [Hash] committed offsets that would be deleted
            def plan
              partitions = ::Karafka::Admin
                .read_lags_with_offsets({ consumer_group_id => [topic] })
                .dig(consumer_group_id, topic)

              if partitions.nil? || partitions.empty?
                raise Errors::Mcp::NoDataError, "Topic #{topic} does not exist"
              end

              {
                consumer_group_id: consumer_group_id,
                topic: topic,
                partitions: partitions.map do |partition_id, details|
                  { partition: partition_id, offset: details.fetch(:offset), lag: details.fetch(:lag) }
                end
              }
            end

            # @return [String]
            def consumer_group_id
              @arguments.fetch(:consumer_group_id)
            end

            # @return [String]
            def topic
              @arguments.fetch(:topic)
            end
          end
        end
      end
    end
  end
end
