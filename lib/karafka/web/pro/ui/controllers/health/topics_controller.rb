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
      module Ui
        module Controllers
          module Health
            # Health views aggregated per topic (one summary row per topic). This is the top level
            # of the health section; the per-partition drill-down lives in {PartitionsController}.
            class TopicsController < BaseController
              # Per-action sortable attributes, since the two actions render different row models:
              # `index` rows are {Models::Health::AggregatedTopic} (report-based, with LSO risk, poll
              # state and trend), while `cluster_lags` rows are {Models::Health::AggregatedClusterTopic}
              # which only exposes the lag-derived metrics Kafka reports.
              self.sortable_attributes = {
                index: %w[
                  name
                  present_count
                  partitions_count
                  lag_hybrid
                  lag_hybrid_d
                  max_lag
                  avg_lag
                  lso_risk_state
                  paused_count
                ].freeze,
                cluster_lags: %w[
                  name
                  partitions_count
                  lag
                  max_lag
                  avg_lag
                ].freeze
              }.freeze

              # The health stats are a tree keyed by consumer group and then topic name, so we filter
              # on those keys rather than on record attributes. Topic keys live under `:topics` in the
              # aggregated topics view but directly under the consumer group in the cluster lags view;
              # the key alias descends leniently, so one declaration covers both shapes without
              # reshaping the data.
              self.filterable_attributes = [
                Lib::Filtering.key(:topic, under: :topics),
                Lib::Filtering.key(:consumer_group)
              ].freeze

              # Displays a per-topic aggregated overview, so instead of a row per partition we get a
              # single summary row per topic. This is the default health landing page: it lets one
              # answer "is anything off?" at a glance and drill down into a topic only when needed.
              def index
                current_state = Models::ConsumersState.current!
                @stats = Models::Health::TopicsAggregation.call(current_state)

                # Sort the aggregated topic rows within each consumer group (by name/lag/etc.)
                @stats.each_value { |cg_details| sort(cg_details[:topics]) }

                filter(@stats)

                render
              end

              # Displays per-topic aggregated lags taken from the cluster (what Kafka sees) for the
              # routing defined consumer groups, not from the reported metrics. Useful when no
              # consumers are running but we still want to check lags. Like the topics view it is
              # aggregated per topic, with a per-partition drill-down (the cluster lags lens of
              # {PartitionsController}).
              def cluster_lags
                @stats = Models::Health::ClusterLagsAggregation.call

                # Sort the aggregated topic rows within each consumer group (by name/lag/etc.)
                @stats.each_value { |cg_topics| sort(cg_topics) }

                filter(@stats)

                render
              end
            end
          end
        end
      end
    end
  end
end
