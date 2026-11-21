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
          # Per-topic health from the consumers reports, as on the Web UI Health page
          class Health < Base
            tool(
              "karafka_health",
              <<~TEXT.tr("\n", " ").strip,
                Per consumer group and topic health reported by the running consumers, as on the
                Web UI Health page: total, max and average lag, lag change, the partition with the
                highest lag, LSO risk state, paused partitions and partitions without data. Lag
                values of -1 mean not available yet. The lag change can be negative, so use
                measurable_count to check if any partition has lag data.
              TEXT
              contract: Contracts::Health.new
            )

            private

            # @return [Hash] health data
            def fetch
              state = Web::Ui::Models::ConsumersState.current!
              stats = Web::Ui::Models::Health::TopicsAggregation.call(state)

              consumer_groups = stats.transform_values do |details|
                {
                  rebalanced_at: details[:rebalanced_at],
                  topics: details[:topics].transform_values(&:to_h)
                }
              end

              { consumer_groups: consumer_groups }
            end
          end
        end
      end
    end
  end
end
