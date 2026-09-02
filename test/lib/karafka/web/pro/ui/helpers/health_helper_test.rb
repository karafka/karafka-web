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
  include described_class

  # Default config.ui.health.lags: high_threshold 10_000, warning_ratio 0.5 (warning at 5_000)
  describe "#lag_severity" do
    it { assert_nil(lag_severity(-1)) }
    it { assert_nil(lag_severity(0)) }
    it { assert_nil(lag_severity(4_999)) }
    it { assert_equal(:warning, lag_severity(5_000)) }
    it { assert_equal(:warning, lag_severity(9_999)) }
    it { assert_equal(:error, lag_severity(10_000)) }
    it { assert_equal(:error, lag_severity(1_000_000)) }

    context "when the warning_ratio is customized" do
      before { ::Karafka::Web.config.ui.health.lags.warning_ratio = 0.25 }

      after { ::Karafka::Web.config.ui.health.lags.warning_ratio = 0.5 }

      it { assert_nil(lag_severity(2_499)) }
      it { assert_equal(:warning, lag_severity(2_500)) }
      it { assert_equal(:error, lag_severity(10_000)) }
    end
  end

  describe "#lag_status_row" do
    it { assert_equal("status-row-error", lag_status_row(10_000)) }
    it { assert_equal("status-row-warning", lag_status_row(5_000)) }
    it { assert_equal("", lag_status_row(100)) }
    it { assert_equal("", lag_status_row(-1)) }
  end

  describe "#topic_lag_status_row" do
    def topic_stub(avg_lag:, skewed:)
      obj = Object.new
      obj.define_singleton_method(:avg_lag) { avg_lag }
      obj.define_singleton_method(:skewed?) { skewed }
      obj
    end

    it "flags high average lag as an error" do
      assert_equal("status-row-error", topic_lag_status_row(topic_stub(avg_lag: 10_000, skewed: false)))
    end

    it "flags medium average lag as a warning" do
      assert_equal("status-row-warning", topic_lag_status_row(topic_stub(avg_lag: 5_000, skewed: false)))
    end

    it "flags a skewed topic as a warning even when the average lag is low" do
      assert_equal("status-row-warning", topic_lag_status_row(topic_stub(avg_lag: 10, skewed: true)))
    end

    it "flags a topic with paused partitions as a warning even when the average lag is low" do
      assert_equal(
        "status-row-warning",
        topic_lag_status_row(topic_stub(avg_lag: 10, skewed: false), paused: true)
      )
    end

    it "keeps error precedence over a skew warning" do
      assert_equal("status-row-error", topic_lag_status_row(topic_stub(avg_lag: 10_000, skewed: true)))
    end

    it "returns no class for a healthy topic" do
      assert_equal("", topic_lag_status_row(topic_stub(avg_lag: 10, skewed: false)))
    end
  end

  describe "#partition_status_row" do
    def partition_stub(lag_hybrid:, process_status: "running", poll_state: "active")
      process = Object.new
      process.define_singleton_method(:status) { process_status }

      details = Object.new
      details.define_singleton_method(:lag_hybrid) { lag_hybrid }
      details.define_singleton_method(:poll_state) { poll_state }
      details.define_singleton_method(:process) { process }
      details
    end

    it "flags a high lag as an error" do
      assert_equal("status-row-error", partition_status_row(partition_stub(lag_hybrid: 10_000)))
    end

    it "flags a stopped process as stopped (red) even without lag" do
      assert_equal(
        "status-row-stopped",
        partition_status_row(partition_stub(lag_hybrid: 0, process_status: "stopped"))
      )
    end

    it "flags a warning-level lag as a warning" do
      assert_equal("status-row-warning", partition_status_row(partition_stub(lag_hybrid: 5_000)))
    end

    it "flags a paused partition as a warning even when the lag is fine" do
      assert_equal(
        "status-row-warning",
        partition_status_row(partition_stub(lag_hybrid: 0, poll_state: "paused"))
      )
    end

    it "keeps a high lag as an error even when the partition is paused" do
      assert_equal(
        "status-row-error",
        partition_status_row(partition_stub(lag_hybrid: 10_000, poll_state: "paused"))
      )
    end

    it "keeps a stopped process red even when the partition is paused" do
      assert_equal(
        "status-row-stopped",
        partition_status_row(partition_stub(lag_hybrid: 0, process_status: "stopped", poll_state: "paused"))
      )
    end

    it "falls back to the process status for a healthy running partition" do
      assert_equal("status-row-running", partition_status_row(partition_stub(lag_hybrid: 0)))
    end

    it "surfaces a winding-down process as its own status class" do
      assert_equal(
        "status-row-quiet",
        partition_status_row(partition_stub(lag_hybrid: 0, process_status: "quiet"))
      )
    end
  end
end
