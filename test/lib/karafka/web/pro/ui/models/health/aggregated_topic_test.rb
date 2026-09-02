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

describe Karafka::Web::Ui::Models::Health::AggregatedTopic do
  let(:aggregated) { described_class.new(topic_name, topic_details) }

  let(:topic_name) { "orders" }

  let(:topic_details) do
    {
      partitions: partitions,
      partitions_count: partitions_count
    }
  end

  let(:partitions_count) { partitions.size }

  # Builds a `Models::Partition` with sane defaults so each test only has to specify the fields it
  # cares about. Defaults describe a healthy, actively polling partition with no LSO risk.
  def partition(id, **overrides)
    defaults = {
      id: id,
      partition_id: id,
      lag: 0,
      lag_d: 0,
      lag_stored: 0,
      lag_stored_d: 0,
      committed_offset: 100,
      stored_offset: 100,
      hi_offset: 100,
      ls_offset: 100,
      ls_offset_fd: 0,
      poll_state: "active"
    }

    Karafka::Web::Ui::Models::Partition.new(defaults.merge(overrides))
  end

  describe "#name" do
    let(:partitions) { { 0 => partition(0) } }

    it "expect to expose the topic name (for sorting)" do
      assert_equal("orders", aggregated.name)
    end
  end

  describe "#partitions_count and #present_count" do
    let(:partitions) { { 0 => partition(0), 1 => partition(1) } }
    let(:partitions_count) { 5 }

    it "expect present_count to reflect the reported partitions" do
      assert_equal(2, aggregated.present_count)
    end

    it "expect partitions_count to reflect the cluster partition count" do
      assert_equal(5, aggregated.partitions_count)
    end
  end

  describe "#no_data_count" do
    context "when some assigned partitions have no data" do
      let(:partitions) { { 0 => partition(0) } }
      let(:partitions_count) { 3 }

      it "expect to count the missing partitions below the reported count" do
        # partitions 1 and 2 have no data
        assert_equal(2, aggregated.no_data_count)
      end
    end

    context "when every partition has data" do
      let(:partitions) { { 0 => partition(0), 1 => partition(1) } }

      it { assert_equal(0, aggregated.no_data_count) }
    end

    context "when more partitions report than the count (data merged across processes)" do
      let(:partitions) { { 0 => partition(0), 1 => partition(1), 2 => partition(2) } }
      let(:partitions_count) { 1 }

      it "expect no partitions to be counted as missing" do
        assert_equal(0, aggregated.no_data_count)
      end
    end
  end

  describe "#lag_hybrid" do
    context "when partitions have lag available" do
      let(:partitions) do
        {
          0 => partition(0, lag: 100, lag_stored: 100),
          1 => partition(1, lag: 900, lag_stored: 900)
        }
      end

      it "expect to sum the hybrid lag across partitions" do
        assert_equal(1_000, aggregated.lag_hybrid)
      end
    end

    context "when only some partitions have lag available" do
      let(:partitions) do
        {
          0 => partition(0, lag: 100, lag_stored: 100),
          1 => partition(1, lag: -1, lag_stored: -1)
        }
      end

      it "expect to sum only the available lags" do
        assert_equal(100, aggregated.lag_hybrid)
      end
    end

    context "when no partition has lag available" do
      let(:partitions) do
        {
          0 => partition(0, lag: -1, lag_stored: -1),
          1 => partition(1, lag: -1, lag_stored: -1)
        }
      end

      it "expect to return -1 (N/A)" do
        assert_equal(-1, aggregated.lag_hybrid)
      end
    end

    context "when there are no partitions at all" do
      let(:partitions) { {} }
      let(:partitions_count) { 0 }

      it "expect to return -1 (N/A)" do
        assert_equal(-1, aggregated.lag_hybrid)
      end
    end
  end

  describe "#lag_hybrid_d" do
    let(:partitions) do
      {
        0 => partition(0, lag: 100, lag_stored: 100, lag_d: 5, lag_stored_d: 5),
        1 => partition(1, lag: 900, lag_stored: 900, lag_d: -2, lag_stored_d: -2)
      }
    end

    it "expect to sum the hybrid lag deltas (trend), keeping the sign" do
      assert_equal(3, aggregated.lag_hybrid_d)
    end

    context "when a partition has no lag available" do
      let(:partitions) do
        {
          0 => partition(0, lag: 100, lag_stored: 100, lag_d: 5, lag_stored_d: 5),
          1 => partition(1, lag: -1, lag_stored: -1, lag_d: -1, lag_stored_d: -1)
        }
      end

      it "expect to ignore the unavailable partition delta" do
        assert_equal(5, aggregated.lag_hybrid_d)
      end
    end
  end

  describe "#max_lag and #max_lag_partition_id" do
    context "when several partitions have lag" do
      let(:partitions) do
        {
          0 => partition(0, lag: 100, lag_stored: 100),
          1 => partition(1, lag: 10_000, lag_stored: 10_000),
          2 => partition(2, lag: 50, lag_stored: 50)
        }
      end

      it "expect to expose the biggest single-partition lag" do
        assert_equal(10_000, aggregated.max_lag)
      end

      it "expect to expose the id of the partition with the biggest lag" do
        assert_equal(1, aggregated.max_lag_partition_id)
      end

      it "expect the max to be distinguishable from an even distribution" do
        # 10_000 concentrated on one partition here, versus the same total spread out, must be
        # visible via max_lag even when the totals are identical
        assert_equal(10_150, aggregated.lag_hybrid)
        assert_equal(10_000, aggregated.max_lag)
      end
    end

    context "when no partition has lag" do
      let(:partitions) do
        { 0 => partition(0, lag: -1, lag_stored: -1) }
      end

      it "expect max_lag to be -1 (N/A)" do
        assert_equal(-1, aggregated.max_lag)
      end

      it "expect max_lag_partition_id to be the -1 sentinel (never nil)" do
        assert_equal(-1, aggregated.max_lag_partition_id)
      end
    end
  end

  describe "#avg_lag" do
    context "when partitions have lag available" do
      let(:partitions) do
        {
          0 => partition(0, lag: 100, lag_stored: 100),
          1 => partition(1, lag: 900, lag_stored: 900)
        }
      end

      it "expect to average only the available lags" do
        assert_equal(500, aggregated.avg_lag)
      end
    end

    context "when only some partitions have lag available" do
      let(:partitions) do
        {
          0 => partition(0, lag: 300, lag_stored: 300),
          1 => partition(1, lag: -1, lag_stored: -1)
        }
      end

      it "expect to average over the measurable partitions only" do
        assert_equal(300, aggregated.avg_lag)
      end
    end

    context "when no partition has lag available" do
      let(:partitions) { { 0 => partition(0, lag: -1, lag_stored: -1) } }

      it "expect to return -1 (N/A)" do
        assert_equal(-1, aggregated.avg_lag)
      end
    end
  end

  describe "#lso_risk_state" do
    # active: last stable offset caught up to the high watermark
    def active_partition(id)
      partition(id, hi_offset: 1_000, ls_offset: 1_000, committed_offset: 1_000)
    end

    # at_risk: LSO behind and frozen, but we have not committed up to it yet
    def at_risk_partition(id)
      partition(
        id,
        hi_offset: 3_000,
        ls_offset: 2_000,
        committed_offset: 1_000,
        ls_offset_fd: 1_000_000_000
      )
    end

    # stopped: LSO behind and frozen, and we have already committed up to it
    def stopped_partition(id)
      partition(
        id,
        hi_offset: 3_000,
        ls_offset: 2_000,
        committed_offset: 2_000,
        ls_offset_fd: 1_000_000_000
      )
    end

    context "when all partitions are active" do
      let(:partitions) { { 0 => active_partition(0), 1 => active_partition(1) } }

      it { assert_equal(:active, aggregated.lso_risk_state) }
    end

    context "when one partition is at risk" do
      let(:partitions) { { 0 => active_partition(0), 1 => at_risk_partition(1) } }

      it "expect the worst (at_risk) to win" do
        assert_equal(:at_risk, aggregated.lso_risk_state)
      end
    end

    context "when one partition is stopped and another only at risk" do
      let(:partitions) { { 0 => at_risk_partition(0), 1 => stopped_partition(1) } }

      it "expect the worst (stopped) to win" do
        assert_equal(:stopped, aggregated.lso_risk_state)
      end
    end

    context "when there are no partitions" do
      let(:partitions) { {} }
      let(:partitions_count) { 0 }

      it { assert_equal(:active, aggregated.lso_risk_state) }
    end
  end

  describe "#paused_count" do
    let(:partitions) do
      {
        0 => partition(0, poll_state: "active"),
        1 => partition(1, poll_state: "paused"),
        2 => partition(2, poll_state: "paused")
      }
    end

    it "expect to count the non-active partitions" do
      assert_equal(2, aggregated.paused_count)
    end

    context "when all partitions are active" do
      let(:partitions) { { 0 => partition(0), 1 => partition(1) } }

      it { assert_equal(0, aggregated.paused_count) }
    end
  end

  describe "#unhealthy?" do
    context "when everything is healthy" do
      let(:partitions) { { 0 => partition(0), 1 => partition(1) } }

      it { refute(aggregated.unhealthy?) }
    end

    context "when a partition is paused" do
      let(:partitions) { { 0 => partition(0), 1 => partition(1, poll_state: "paused") } }

      it { assert(aggregated.unhealthy?) }
    end

    context "when some partitions have no data" do
      let(:partitions) { { 0 => partition(0) } }
      let(:partitions_count) { 3 }

      it { assert(aggregated.unhealthy?) }
    end

    context "when a partition LSO is stopped" do
      let(:partitions) do
        {
          0 => partition(
            0,
            hi_offset: 3_000,
            ls_offset: 2_000,
            committed_offset: 2_000,
            ls_offset_fd: 1_000_000_000
          )
        }
      end

      it { assert(aggregated.unhealthy?) }
    end
  end
end
