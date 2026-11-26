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

describe_current do
  let(:result) { described_class.new(arguments).call }
  let(:arguments) { {} }
  let(:structured) { result.fetch(:structuredContent) }

  context "when a routed consumer group has lags" do
    let(:lagging_topic) { create_topic }
    let(:lagging_group) { "it-cluster-lags-#{SecureRandom.uuid}" }

    before do
      produce_many(lagging_topic, Array.new(100) { SecureRandom.uuid })

      group = lagging_group
      topic_name = lagging_topic
      draw_routes do
        consumer_group group do
          topic topic_name do
            consumer Karafka::BaseConsumer
          end
        end
      end

      Karafka::Admin.seek_consumer_group(lagging_group, lagging_topic => { 0 => 40 })
    end

    it "returns the per-topic lags read from Kafka" do
      refute(result[:isError])

      row = structured.dig(:consumer_groups, lagging_group, :topics, lagging_topic)

      assert_equal(lagging_topic, row[:name])
      assert_equal(60, row[:total_lag])
      assert_equal(0, row[:max_lag_partition_id])
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end

    context "when the group has lags on an inactive topic" do
      let(:inactive_topic) { create_topic }
      let(:visibility) { Karafka::Web.config.ui.visibility }

      before do
        produce_many(inactive_topic, Array.new(10) { SecureRandom.uuid })

        group = lagging_group
        inactive_topic_name = inactive_topic
        draw_routes do
          consumer_group group do
            topic inactive_topic_name do
              consumer Karafka::BaseConsumer
              active false
            end
          end
        end

        Karafka::Admin.seek_consumer_group(lagging_group, inactive_topic => { 0 => 5 })
      end

      after { visibility.active_topics_cluster_lags_only = true }

      it "hides that topic as the Web UI does by default" do
        topics = structured.dig(:consumer_groups, lagging_group, :topics)

        assert(topics.key?(lagging_topic))
        refute(topics.key?(inactive_topic))
      end

      it "shows that topic when the Web UI shows inactive topics lags" do
        visibility.active_topics_cluster_lags_only = false

        row = structured.dig(:consumer_groups, lagging_group, :topics, inactive_topic)

        assert_equal(5, row[:total_lag])
      end
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "topic" => "test" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
