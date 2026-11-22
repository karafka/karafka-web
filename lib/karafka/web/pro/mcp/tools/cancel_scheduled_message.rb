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
          # Cancels a scheduled message, as the Web UI scheduled message Cancel action
          class CancelScheduledMessage < Base
            tool(
              "karafka_cancel_scheduled_message",
              <<~TEXT.tr("\n", " ").strip,
                Cancels a scheduled message so it is not dispatched, as the Web UI scheduled
                message Cancel action does. Point to the message in the scheduled messages topic.
                It cannot be undone.
              TEXT
              contract: Contracts::Message.new,
              operation: :produce,
              destructive: true,
              idempotent: true,
              properties: {
                topic: { type: "string", description: "Scheduled messages topic name" },
                partition: { type: "integer", minimum: 0, description: "Partition of the topic" },
                offset: { type: "integer", minimum: 0, description: "Scheduled message offset" }
              },
              required: %w[topic partition offset]
            )

            # @return [Array<String>] the scheduled messages topic
            def topics
              [topic]
            end

            # @return [Array(String, String)] Web UI request of the matching action
            def ui_request
              ["POST", "/scheduled_messages/messages/#{topic}/#{partition}/#{offset}/cancel"]
            end

            private

            # @return [Hash] cancelled message details
            def fetch
              change = plan

              cancel_message = ::Karafka::Pro::ScheduledMessages.cancel(
                key: change.fetch(:key),
                envelope: { topic: topic, partition: partition }
              )

              ::Karafka::Web.producers.acked.produce_sync(cancel_message)

              { cancelled: true }.merge(change)
            end

            # @return [Hash] scheduled message that would be cancelled
            def plan
              message = Web::Ui::Lib::Admin.read_topic(topic, partition, 1, offset).first

              if message.nil? || message.offset != offset
                raise Errors::Mcp::NoDataError, "No message under offset #{offset} of #{topic}##{partition}"
              end

              { topic: topic, partition: partition, offset: offset, key: message.key }
            end

            # @return [String]
            def topic
              @arguments.fetch(:topic)
            end

            # @return [Integer]
            def partition
              @arguments.fetch(:partition)
            end

            # @return [Integer]
            def offset
              @arguments.fetch(:offset)
            end
          end
        end
      end
    end
  end
end
