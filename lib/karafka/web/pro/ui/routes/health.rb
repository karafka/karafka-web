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
        module Routes
          # Manages the health related routes
          class Health < Base
            route do |r|
              r.on "health" do
                topics_controller = build(Controllers::Health::TopicsController)

                # Cluster lags is the second top-level view: a cluster-wide, routing-based lag
                # report, aggregated per topic. Its per-partition drill-down is the `cluster_lags`
                # lens of the per-topic view below.
                r.get "cluster_lags" do
                  topics_controller.cluster_lags
                end

                # Per-topic drill-down. The per-partition lenses (overview/lags/offsets/changes and
                # cluster_lags) live here, scoped to a single topic, instead of the old top-level
                # all-topics views which became unusable with many topics/partitions.
                r.on "topics", String, String do |consumer_group_id, topic_name|
                  partitions_controller = build(Controllers::Health::PartitionsController)

                  r.get "overview" do
                    partitions_controller.overview(consumer_group_id, topic_name)
                  end

                  r.get "lags" do
                    partitions_controller.lags(consumer_group_id, topic_name)
                  end

                  r.get "offsets" do
                    partitions_controller.offsets(consumer_group_id, topic_name)
                  end

                  r.get "changes" do
                    partitions_controller.changes(consumer_group_id, topic_name)
                  end

                  r.get "cluster_lags" do
                    partitions_controller.cluster_lags(consumer_group_id, topic_name)
                  end

                  # A bare topic path defaults to the overview lens
                  r.get do
                    r.redirect root_path("health", "topics", consumer_group_id, topic_name, "overview")
                  end
                end

                # A consumer-group path without a topic has no page of its own, so send it to the
                # topics list scoped to that group rather than 404-ing. `health_group_topics_path`
                # URL-encodes the group value (it comes from the URL path) so it cannot inject extra
                # query params.
                r.get "topics", String do |consumer_group_id|
                  r.redirect health_group_topics_path(consumer_group_id)
                end

                r.get "topics" do
                  topics_controller.index
                end

                r.get do
                  r.redirect root_path("health/topics")
                end
              end
            end
          end
        end
      end
    end
  end
end
