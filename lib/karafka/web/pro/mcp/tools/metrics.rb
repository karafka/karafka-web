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
          # Historical metrics, the same as the charts of the Web UI dashboard
          class Metrics < Base
            # Time ranges of the metrics, as in the Web UI dashboard
            RANGES = Web::Ui::Controllers::Requests::Params::ALLOWED_RANGES

            private_constant :RANGES

            tool(
              "karafka_metrics",
              <<~TEXT.tr("\n", " ").strip,
                Historical metrics of the Karafka consumers, as on the Web UI dashboard charts,
                as [unix_time, values] samples. "aggregated" holds the per sample deltas of
                messages, batches, jobs, errors, retries and dead messages, plus utilization,
                memory, processes, workers and listeners. "topics" holds, per
                "topic[consumer_group]", the lag (lag_hybrid), pace (sum of high watermarks)
                and last stable offset freeze duration (ls_offset_fd, ms).
              TEXT
              contract: Contracts::Metrics.new,
              properties: {
                range: {
                  type: "string",
                  enum: RANGES,
                  default: RANGES.first,
                  description: "Time range of the samples"
                }
              }
            )

            private

            # @return [Hash] metrics for the requested range
            def fetch
              range = @arguments.fetch(:range, RANGES.first)
              metrics = Web::Ui::Models::ConsumersMetrics.current!.to_h
              aggregated = Web::Ui::Models::Metrics::Aggregated.new(metrics.fetch(:aggregated))
              topics = Web::Ui::Models::Metrics::Topics.new(metrics.fetch(:consumer_groups))

              {
                range: range,
                aggregated: aggregated.to_h.fetch(range.to_sym),
                topics: topics.to_h.fetch(range.to_sym)
              }
            end
          end
        end
      end
    end
  end
end
