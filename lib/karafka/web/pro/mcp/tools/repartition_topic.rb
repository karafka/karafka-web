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
          # Adds partitions to a topic, as the Web UI topic repartition action
          class RepartitionTopic < TopicChange
            tool(
              "karafka_repartition_topic",
              <<~TEXT.tr("\n", " ").strip,
                Increases the number of partitions of a topic, as the Web UI topic repartition
                action does. Kafka cannot remove partitions, and keyed messages may go to other
                partitions afterwards. It cannot be undone.
              TEXT
              contract: Contracts::TopicRepartitioning.new,
              operation: :repartition_topic,
              destructive: true,
              idempotent: true,
              properties: {
                topic: { type: "string", description: "Name of the topic" },
                partitions: {
                  type: "integer",
                  minimum: 1,
                  description: "New number of partitions, greater than the current one"
                }
              },
              required: %w[topic partitions]
            )

            private

            # @return [Hash] repartitioning details
            def fetch
              change = plan

              Ui::Lib::Topics::Repartitioning::Dispatcher.new(topic, @form).call

              { started: true }.merge(change)
            end

            # @return [Hash] partitions count change
            def plan
              @form = Ui::Lib::Topics::Repartitioning::Normalizer.call(
                partition_count: @arguments.fetch(:partitions).to_s
              )

              validate(
                Ui::Lib::Topics::Repartitioning::Contracts::Form,
                @form.merge(current_partition_count: current.partition_count)
              )

              { topic: topic, from: current.partition_count, to: @arguments.fetch(:partitions) }
            end
          end
        end
      end
    end
  end
end
