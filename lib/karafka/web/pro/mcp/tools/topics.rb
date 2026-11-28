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
          # Topics of the cluster, as on the Web UI Topics page
          class Topics < Base
            tool(
              "karafka_topics",
              <<~TEXT.tr("\n", " ").strip,
                Topics of the Kafka cluster, as on the Web UI Topics page: name and partition
                count of each topic, sorted by name. Internal topics (starting with __) are listed
                only when the Web UI shows them. Use karafka_topic_configs to read a topic configs.
              TEXT
              contract: Contracts::NoArguments.new
            )

            private

            # @return [Hash] topics data
            def fetch
              topics = Ui::Models::Cluster::Topic.all.sort_by(&:topic_name)

              unless ::Karafka::Web.config.ui.visibility.internal_topics
                topics.delete_if { |topic| topic[:topic_name].start_with?("__") }
              end

              {
                topics: topics.map do |topic|
                  { topic_name: topic[:topic_name], partition_count: topic[:partition_count] }
                end
              }
            end
          end
        end
      end
    end
  end
end
