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
          # Deletes a topic, as the Web UI topic delete action
          class DeleteTopic < Base
            tool(
              "karafka_delete_topic",
              <<~TEXT.tr("\n", " ").strip,
                Deletes a topic with all its messages, as the Web UI topic delete action does.
                It cannot be undone.
              TEXT
              contract: Contracts::Topic.new,
              operation: :delete_topic,
              destructive: true,
              idempotent: true,
              properties: {
                topic: { type: "string", description: "Name of the topic to delete" }
              },
              required: %w[topic]
            )

            # Topics management must be enabled and internal topics visible, as in the Web UI
            def authorize!
              deny!("Topics management is disabled") unless Ui::Lib::Features.topics_management?

              return if ::Karafka::Web.config.ui.visibility.internal_topics
              return unless topic.start_with?("__")

              deny!("Internal topics are hidden in the Web UI")
            end

            # @return [Array<String>] the deleted topic
            def topics
              [topic]
            end

            private

            # @return [Hash] deleted topic
            def fetch
              change = plan

              ::Karafka::Admin.delete_topic(topic)
              ::Karafka::Web.config.ui.cache.clear

              { deleted: true }.merge(change)
            end

            # @return [Hash] topic that would be deleted
            def plan
              { topic: topic, partitions: Web::Ui::Models::Topic.find(topic).partition_count }
            rescue Errors::Ui::NotFoundError
              raise Errors::Mcp::NoDataError, "Topic #{topic} does not exist"
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
