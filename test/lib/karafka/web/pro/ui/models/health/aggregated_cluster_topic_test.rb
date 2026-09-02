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

describe Karafka::Web::Ui::Models::Health::AggregatedClusterTopic do
  let(:aggregated) { described_class.new("orders", partitions) }

  def partition(id, lag:, stored_offset: 0)
    { id: id, lag: lag, stored_offset: stored_offset }
  end

  describe "#name" do
    let(:partitions) { [partition(0, lag: 1)] }

    it "expect to expose the topic name (for sorting)" do
      assert_equal("orders", aggregated.name)
    end
  end

  describe "#partitions_count" do
    let(:partitions) { [partition(0, lag: 1), partition(1, lag: 2)] }

    it { assert_equal(2, aggregated.partitions_count) }
  end

  describe "#lag" do
    context "when partitions have lag" do
      let(:partitions) { [partition(0, lag: 100), partition(1, lag: 900)] }

      it "expect to sum the lags" do
        assert_equal(1_000, aggregated.lag)
      end
    end

    context "when a partition was never consumed (negative lag)" do
      let(:partitions) { [partition(0, lag: 100), partition(1, lag: -1)] }

      it "expect to exclude it from the sum" do
        assert_equal(100, aggregated.lag)
      end
    end

    context "when no partition was consumed" do
      let(:partitions) { [partition(0, lag: -1)] }

      it "expect to return -1 (N/A)" do
        assert_equal(-1, aggregated.lag)
      end
    end
  end

  describe "#max_lag and #max_lag_partition_id" do
    let(:partitions) do
      [
        partition(0, lag: 100),
        partition(1, lag: 9_000),
        partition(2, lag: 50)
      ]
    end

    it "expect to expose the biggest single-partition lag and its id" do
      assert_equal(9_000, aggregated.max_lag)
      assert_equal(1, aggregated.max_lag_partition_id)
    end

    context "when no partition was consumed" do
      let(:partitions) { [partition(0, lag: -1)] }

      it "expect the -1 sentinels (never nil)" do
        assert_equal(-1, aggregated.max_lag)
        assert_equal(-1, aggregated.max_lag_partition_id)
      end
    end
  end

  describe "#avg_lag" do
    context "when partitions have lag" do
      let(:partitions) { [partition(0, lag: 100), partition(1, lag: 900)] }

      it { assert_equal(500, aggregated.avg_lag) }
    end

    context "when only some partitions were consumed" do
      let(:partitions) { [partition(0, lag: 300), partition(1, lag: -1)] }

      it "expect to average only the measurable partitions" do
        assert_equal(300, aggregated.avg_lag)
      end
    end

    context "when no partition was consumed" do
      let(:partitions) { [partition(0, lag: -1)] }

      it "expect to return -1 (N/A)" do
        assert_equal(-1, aggregated.avg_lag)
      end
    end
  end
end
