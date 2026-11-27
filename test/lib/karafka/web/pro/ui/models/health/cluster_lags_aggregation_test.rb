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
  let(:aggregated) { described_class.call }

  before do
    Karafka::Admin.stubs(:read_lags_with_offsets).returns(
      "app" => {
        "orders" => {
          0 => { lag: 100, offset: 5 },
          1 => { lag: 900, offset: 10 }
        }
      }
    )
  end

  it "expect to collapse each topic into an AggregatedClusterTopic summary" do
    topic_stats = aggregated["app"]["orders"]

    assert_instance_of(Karafka::Web::Pro::Ui::Models::Health::AggregatedClusterTopic, topic_stats)
    assert_equal(2, topic_stats.partitions_count)
    assert_equal(1_000, topic_stats.lag)
    assert_equal(900, topic_stats.max_lag)
    assert_equal(1, topic_stats.max_lag_partition_id)
    assert_equal(500, topic_stats.avg_lag)
  end

  context "when the cluster reports groups and topics out of order" do
    before do
      Karafka::Admin.stubs(:read_lags_with_offsets).returns(
        "zeta" => {
          "orders" => { 0 => { lag: 1, offset: 1 } }
        },
        "alpha" => {
          "visits" => { 0 => { lag: 1, offset: 1 } },
          "default" => { 0 => { lag: 1, offset: 1 } }
        }
      )
    end

    it "expect consumer groups and topics to be alphabetically ordered (like the topics view)" do
      assert_equal(%w[alpha zeta], aggregated.keys)
      assert_equal(%w[default visits], aggregated["alpha"].keys)
    end
  end
end
