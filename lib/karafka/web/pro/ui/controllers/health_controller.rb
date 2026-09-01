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
          # Health state controller
          class HealthController < BaseController
            self.sortable_attributes = %w[
              id
              lag
              lag_d
              lag_stored
              lag_stored_d
              lag_hybrid
              lag_hybrid_d
              committed_offset
              committed_offset_fd
              stored_offset
              stored_offset_fd
              lo_offset
              hi_offset
              hi_offset_fd
              ls_offset
              ls_offset_fd
              fetch_state
              poll_state
              lso_risk_state
              name
              poll_state_ch
            ].freeze

            # The health stats are a tree keyed by consumer group and then topic name, so we filter
            # on those keys rather than on record attributes. Topic keys live under `:topics` in the
            # overview but directly under the consumer group in the cluster lags view; the key alias
            # descends leniently, so one declaration covers both shapes without reshaping the data.
            self.filterable_attributes = [
              Lib::Filtering.key(:topic, under: :topics),
              Lib::Filtering.key(:consumer_group)
            ].freeze

            # Displays a per-topic aggregated overview, so instead of a row per partition we get a
            # single summary row per topic. This is the default health landing page: it lets one
            # answer "is anything off?" at a glance and drill down into a topic only when needed.
            def topics
              current_state = Models::ConsumersState.current!
              @stats = Models::Health.aggregated(current_state)

              # Same key-based tree as overview, so the topic/consumer group filter works as-is
              filter(@stats)

              render
            end

            # Displays the per-partition details of a single topic within a consumer group. This is
            # the drill-down target of the aggregated topics view and reuses the overview table.
            #
            # @param consumer_group_id [String] id of the consumer group
            # @param topic_name [String] name of the topic
            def topic(consumer_group_id, topic_name)
              current_state = Models::ConsumersState.current!
              stats = Models::Health.current(current_state)

              @consumer_group_id = consumer_group_id
              @topic_name = topic_name
              @cg_details = stats[consumer_group_id]
              @topic_details = @cg_details && @cg_details[:topics][topic_name]

              not_found!(topic_name) unless @topic_details

              # Reuse the per-partition sortable attributes exposed for the overview table
              sort(@topic_details)

              render
            end

            # Displays the current system state
            def overview
              current_state = Models::ConsumersState.current!
              @stats = Models::Health.current(current_state)

              # Sort only on a per topic basis not to resort higher levels
              @stats.each_value do |cg_details|
                cg_details.each_value { |topic_details| sort(topic_details) }
              end

              # Narrow the whole tree down to the consumer groups/topics matching the current filter
              # (if any). It is safe to prune in place here as the stats are built fresh per request.
              filter(@stats)

              render
            end

            # Displays details about lags and their progression/statuses
            def lags
              # Same data as overview but presented differently
              overview

              render
            end

            # Displays lags for routing defined consumer groups taken from the cluster and not
            # the metrics reported. This is useful when we don't have any consumers running but
            # still want to check lags because it shows what Kafka sees
            def cluster_lags
              @stats = Models::Health.cluster_lags_with_offsets

              @stats.each_value do |cg_details|
                cg_details.each_value { |topic_details| sort(topic_details) }
              end

              filter(@stats)

              render
            end

            # Displays details about offsets and their progression/statuses
            def offsets
              # Same data as overview but presented differently
              overview

              render
            end

            # Displays information related to time of changes of particular attributes
            def changes
              # Same data as overview but presented differently
              overview

              render
            end
          end
        end
      end
    end
  end
end
