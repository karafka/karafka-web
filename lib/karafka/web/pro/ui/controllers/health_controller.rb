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
            # Per-partition lenses available when drilling into a single topic. The report-based
            # lenses map 1:1 to the `_<lens>_table` view partials; `cluster_lags` is special-cased in
            # {#topic} as it comes from the cluster (Kafka) rather than the consumer reports.
            LENSES = %i[overview lags offsets changes cluster_lags].freeze

            # The lenses backed by consumer report data (everything but the cluster lags lens)
            REPORT_LENSES = (LENSES - %i[cluster_lags]).freeze

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
              max_lag
              avg_lag
              present_count
              no_data_count
              paused_count
              partitions_count
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

              # Sort the aggregated topic rows within each consumer group (by name/lag/etc.)
              @stats.each_value { |cg_details| sort(cg_details[:topics]) }

              # Same key-based tree as overview, so the topic/consumer group filter works as-is
              filter(@stats)

              render
            end

            # Displays the per-partition details of a single topic within a consumer group, in one of
            # the {LENSES}. The report-based lenses (overview/lags/offsets/changes) reuse the existing
            # per-partition `_<lens>_table` partials; the `cluster_lags` lens shows what Kafka sees
            # (from the cluster) and works even when no consumer is running/reporting the topic.
            # This is the drill-down target of both the aggregated topics and cluster lags views.
            #
            # @param consumer_group_id [String] id of the consumer group
            # @param topic_name [String] name of the topic
            # @param lens [Symbol] which lens to render (one of {LENSES})
            def topic(consumer_group_id, topic_name, lens)
              @consumer_group_id = consumer_group_id
              @topic_name = topic_name
              @lens = lens

              if lens == :cluster_lags
                topic_cluster_lags
              else
                topic_report_lens
              end

              render
            end

            # Displays per-topic aggregated lags for routing defined consumer groups taken from the
            # cluster and not the metrics reported. This is useful when we don't have any consumers
            # running but still want to check lags because it shows what Kafka sees. Like the topics
            # view, it is aggregated per topic with a per-partition drill-down (the cluster lags lens
            # of the per-topic view).
            def cluster_lags
              @stats = Models::Health.aggregated_cluster_lags

              # Sort the aggregated topic rows within each consumer group (by name/lag/etc.)
              @stats.each_value { |cg_topics| sort(cg_topics) }

              filter(@stats)

              render
            end

            private

            # Loads the per-partition consumer report data for the drilled-into topic (used by the
            # overview/lags/offsets/changes lenses). Missing report data is a 404.
            def topic_report_lens
              stats = Models::Health.current(Models::ConsumersState.current!)

              @cg_details = stats[@consumer_group_id]
              @topic_details = @cg_details && @cg_details[:topics][@topic_name]

              not_found!(@topic_name) unless @topic_details

              # Reuse the per-partition sortable attributes exposed for the lens tables
              sort(@topic_details)
            end

            # Loads the per-partition cluster lags for the drilled-into topic (the cluster lags lens).
            # Unlike the report lenses this does not 404 when the topic is absent: a topic with no
            # running consumers legitimately has no cluster lag rows, so we render an empty table
            # rather than a not found, keeping the lens navigable for every topic.
            def topic_cluster_lags
              partitions = Models::Health.cluster_lags_with_offsets.dig(
                @consumer_group_id,
                @topic_name
              )

              @cluster_partitions = sort(partitions || [])
            end
          end
        end
      end
    end
  end
end
