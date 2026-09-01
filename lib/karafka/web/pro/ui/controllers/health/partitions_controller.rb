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
          # Namespace for the health section controllers (aggregated topics and their drill-down).
          module Health
            # Per-partition details of a single topic within a consumer group. This is the
            # drill-down from the aggregated {TopicsController} views. Each action is one lens: the
            # report-based lenses (overview/lags/offsets/changes) come from the consumer reports,
            # while {#cluster_lags} shows what Kafka sees and works even without a running consumer.
            class PartitionsController < BaseController
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

              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def overview(consumer_group_id, topic_name)
                load_report_topic(consumer_group_id, topic_name)

                render
              end

              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def lags(consumer_group_id, topic_name)
                load_report_topic(consumer_group_id, topic_name)

                render
              end

              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def offsets(consumer_group_id, topic_name)
                load_report_topic(consumer_group_id, topic_name)

                render
              end

              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def changes(consumer_group_id, topic_name)
                load_report_topic(consumer_group_id, topic_name)

                render
              end

              # Cluster lags for a single topic, straight from Kafka. Unlike the report lenses this
              # does not 404 when the topic is absent: a topic with no running consumers has no
              # cluster lag rows, so we render an empty table rather than a not found, keeping the
              # lens navigable for every topic.
              #
              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def cluster_lags(consumer_group_id, topic_name)
                @consumer_group_id = consumer_group_id
                @topic_name = topic_name

                partitions = Models::Health.cluster_lags_with_offsets.dig(
                  consumer_group_id,
                  topic_name
                )

                @cluster_partitions = sort(partitions || [])

                render
              end

              private

              # Loads the per-partition consumer report data for the drilled-into topic (used by the
              # overview/lags/offsets/changes lenses). Missing report data is a 404.
              #
              # @param consumer_group_id [String]
              # @param topic_name [String] name of the topic
              def load_report_topic(consumer_group_id, topic_name)
                stats = Models::Health.current(Models::ConsumersState.current!)

                @consumer_group_id = consumer_group_id
                @topic_name = topic_name
                @cg_details = stats[consumer_group_id]
                @topic_details = @cg_details && @cg_details[:topics][topic_name]

                not_found!(topic_name) unless @topic_details

                # Reuse the per-partition sortable attributes exposed for the lens tables
                sort(@topic_details)
              end
            end
          end
        end
      end
    end
  end
end
