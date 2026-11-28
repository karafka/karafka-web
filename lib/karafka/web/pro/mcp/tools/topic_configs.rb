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
          # Configs of one topic, as on the Web UI topic Configuration page
          class TopicConfigs < Base
            tool(
              "karafka_topic_configs",
              <<~TEXT.tr("\n", " ").strip,
                Configs of one topic as Kafka describes them, as on the Web UI topic Configuration
                page: name, value, source, synonyms and the default, sensitive and read-only flags
                of each config. Use karafka_topics to find the topic name.
              TEXT
              contract: Contracts::Topics::Configs.new,
              required: %w[topic_name],
              properties: {
                topic_name: {
                  type: "string",
                  description: "Name of the topic"
                }
              }
            )

            private

            # @return [Hash] topic configs
            def fetch
              topic_name = @arguments.fetch(:topic_name)

              {
                topic_name: topic_name,
                untrusted_fields: %w[configs.value],
                note: UNTRUSTED_NOTE,
                configs: find_topic(topic_name).configs.sort_by(&:name).map { |config| serialize(config) }
              }
            end

            # @param config [Karafka::Admin::Configs::Config]
            # @return [Hash] config details
            def serialize(config)
              {
                name: config.name,
                value: config.value,
                source: config.source,
                synonyms: config.synonyms.map(&:name),
                default: config.default?,
                sensitive: config.sensitive?,
                read_only: config.read_only?
              }
            end
          end
        end
      end
    end
  end
end
