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

  context "when there is state" do
    let(:consumer_group) { structured.dig(:consumer_groups, "example_app6_app") }

    it "returns the per-topic health without partition details" do
      refute(result[:isError])
      assert_equal(%w[default test2 visits], consumer_group.fetch(:topics).keys)

      consumer_group.fetch(:topics).each_value do |topic|
        refute_includes(topic.keys, :partitions)
      end

      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end

    it "maps the aggregated topic health" do
      assert_in_delta(2_690_818_656.575513, consumer_group[:rebalanced_at])

      topic = consumer_group.dig(:topics, "default")

      assert_equal("default", topic[:name])
      assert_equal(1, topic[:partitions_count])
      assert_equal(213_731_273, topic[:lag_hybrid])
      assert_equal(-3, topic[:lag_hybrid_d])
      assert_equal(213_731_273, topic[:max_lag])
      assert_equal(0, topic[:max_lag_partition_id])
      assert_equal(:active, topic[:lso_risk_state])
      assert_equal(0, topic[:paused_count])
    end

    it "marks topics without lag data" do
      topic = consumer_group.dig(:topics, "test2")

      assert_equal(0, topic[:measurable_count])
      assert_equal(-1, topic[:lag_hybrid])
      assert_equal(-1, topic[:max_lag_partition_id])
    end
  end

  context "when state is missing" do
    before { Karafka::Web.config.topics.consumers.states.name = create_topic }

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "karafka_status")
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "topic" => "test" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
