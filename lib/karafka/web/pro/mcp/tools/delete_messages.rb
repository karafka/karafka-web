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
          # Deletes the messages of a partition below an offset, as the Web UI Explorer Delete
          # messages up to this offset action
          class DeleteMessages < Base
            tool(
              "karafka_delete_messages",
              <<~TEXT.tr("\n", " ").strip,
                Deletes all messages of a topic partition below the given offset, as the Web UI
                Explorer "Delete messages up to this offset" action does. The message at the
                offset stays. It cannot be undone.
              TEXT
              contract: Contracts::Message.new,
              operation: :delete_records,
              destructive: true,
              idempotent: true,
              properties: {
                topic: { type: "string", description: "Topic name" },
                partition: { type: "integer", minimum: 0, description: "Partition of the topic" },
                offset: {
                  type: "integer",
                  minimum: 0,
                  description: "Messages below this offset are deleted"
                }
              },
              required: %w[topic partition offset]
            )

            # The messages policy must allow it, as for the Web UI action
            def authorize!
              policy = ::Karafka::Web.config.ui.policies.messages

              return if policy.delete_records?(topic, partition)

              deny!("The messages policy denies deleting messages of this partition")
            end

            # @return [Array<String>] the topic of the deleted messages
            def topics
              [topic]
            end

            # @return [Array(String, String)] Web UI request of the matching action
            def ui_request
              ["DELETE", "/explorer/messages/#{topic}/#{partition}/#{offset}/delete"]
            end

            private

            # @return [Hash] deleted offsets range
            def fetch
              change = plan

              ::Karafka::Admin.delete_records(topic => [{ partition: partition, offset: offset }])

              ::Karafka.logger.info(
                "Web UI MCP deleted offsets #{change[:from]} to #{offset - 1} " \
                "(up to #{change[:count]} messages) from #{topic}##{partition}"
              )

              { deleted: true }.merge(change)
            end

            # @return [Hash] offsets range that would be deleted
            def plan
              low, high = ::Karafka::Admin.read_watermark_offsets(topic, partition)

              if offset > high
                raise Errors::Mcp::ChangeRefusedError, "Offset #{offset} is past the end of " \
                  "#{topic}##{partition}: its offsets are #{low} to #{high}"
              end

              count = [offset - low, 0].max

              unless count.positive?
                raise Errors::Mcp::ChangeRefusedError, "There are no messages below offset #{offset} " \
                  "in #{topic}##{partition} to delete"
              end

              { topic: topic, partition: partition, from: low, to: offset - 1, count: count }
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
