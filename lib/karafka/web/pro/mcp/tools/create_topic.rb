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
          # Creates a topic, as the Web UI topic create action
          class CreateTopic < TopicChange
            tool(
              "karafka_create_topic",
              <<~TEXT.tr("\n", " ").strip,
                Creates a topic with the given number of partitions and replication factor, as
                the Web UI topic create action does.
              TEXT
              contract: Contracts::TopicCreation.new,
              operation: :create_topic,
              properties: {
                topic: { type: "string", description: "Name of the topic to create" },
                partitions: { type: "integer", minimum: 1, description: "Number of partitions" },
                replication_factor: {
                  type: "integer",
                  minimum: 1,
                  description: "Number of replicas of each partition"
                }
              },
              required: %w[topic partitions replication_factor]
            )

            private

            # @return [Hash] created topic
            def fetch
              form = validate(
                Ui::Lib::Topics::Creation::Contracts::Form,
                Ui::Lib::Topics::Creation::Normalizer.call(
                  topic_name: topic,
                  partitions_count: @arguments.fetch(:partitions).to_s,
                  replication_factor: @arguments.fetch(:replication_factor).to_s
                )
              )

              Ui::Lib::Topics::Creation::Dispatcher.new(form).call
              ::Karafka::Web.config.ui.cache.clear

              {
                created: true,
                topic: topic,
                partitions: @arguments.fetch(:partitions),
                replication_factor: @arguments.fetch(:replication_factor)
              }
            end
          end
        end
      end
    end
  end
end
