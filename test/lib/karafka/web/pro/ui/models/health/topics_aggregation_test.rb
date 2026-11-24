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
  let(:aggregated) { described_class.call(state) }

  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before { Karafka::Web.config.topics.consumers.reports.name = reports_topic }

  context "when none of the processes are active" do
    it { assert_equal({}, aggregated) }
  end

  context "when there are active processes" do
    let(:cg) { "example_app6_app" }
    let(:topic) { "default" }

    before do
      produce(reports_topic, report.to_json)
      produce(reports_topic, report.to_json)
    end

    it "expect to preserve the consumer group => topics tree shape" do
      assert_equal(%w[example_app6_app], aggregated.keys)
      assert_equal(%w[default test2 visits], aggregated[cg][:topics].keys)
      assert_in_delta(2_690_818_656.575_513, aggregated[cg][:rebalanced_at])
    end

    it "expect each topic to be collapsed into an AggregatedTopic summary" do
      topic_stats = aggregated[cg][:topics][topic]

      assert_instance_of(Karafka::Web::Pro::Ui::Models::Health::AggregatedTopic, topic_stats)
      assert_equal(1, topic_stats.partitions_count)
      assert_equal(1, topic_stats.present_count)
      assert_equal(213_731_273, topic_stats.lag_hybrid)
      assert_equal(213_731_273, topic_stats.max_lag)
      assert_equal(0, topic_stats.max_lag_partition_id)
      assert_equal(:active, topic_stats.lso_risk_state)
      assert_equal(0, topic_stats.paused_count)
      assert_equal(0, topic_stats.no_data_count)
    end
  end
end
