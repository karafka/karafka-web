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
          # Per-topic lags read from Kafka, as on the Web UI Health cluster lags page
          class ClusterLags < Base
            tool(
              "karafka_cluster_lags",
              <<~TEXT.tr("\n", " ").strip,
                Per consumer group and topic lags read from Kafka for the consumer groups in the
                routing, as on the Web UI Health cluster lags page: total, max and average lag and
                the partition with the highest lag. It works also when no consumers run. Lag values
                of -1 mean not available.
              TEXT
              contract: Contracts::ClusterLags.new
            )

            private

            # @return [Hash] cluster lags data
            def fetch
              stats = Web::Ui::Models::Health::ClusterLagsAggregation.call

              consumer_groups = stats.transform_values do |topics|
                { topics: topics.transform_values(&:to_h) }
              end

              { consumer_groups: consumer_groups }
            end
          end
        end
      end
    end
  end
end
