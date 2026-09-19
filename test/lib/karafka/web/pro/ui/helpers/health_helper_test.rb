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

  # `health_group_topics_path` builds on PathsHelper#root_path (mixed into the app at runtime)
  def root_path(*args)
    "/karafka/#{args.join("/")}"
  end

  describe "#health_group_topics_path" do
    it "builds the topics path scoped to the consumer group" do
      assert_equal(
        "/karafka/health/topics?filter[field]=consumer_group&filter[value]=app",
        health_group_topics_path("app")
      )
    end

    it "URL-encodes the consumer group value so it cannot inject extra query params" do
      result = health_group_topics_path("evil&injected=1")

      assert_includes(result, "filter[value]=evil%26injected%3D1")
      refute_includes(result, "evil&injected=1")
    end
  end

  describe "#health_lens_label" do
    it { assert_equal("Overview", health_lens_label(:overview)) }
    it { assert_equal("Lags", health_lens_label(:lags)) }
    it { assert_equal("Offsets", health_lens_label(:offsets)) }
    it { assert_equal("Changes", health_lens_label(:changes)) }
    it { assert_equal("Cluster Lags", health_lens_label(:cluster_lags)) }

    it "accepts a string too" do
      assert_equal("Changes", health_lens_label("changes"))
    end

    it "falls back to a titleized name for an unknown lens" do
      assert_equal("Some Lens", health_lens_label(:some_lens))
    end
  end

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

  # Default config.ui.health.lags: skew_threshold 3, skew_minimum 100
  describe "#skewed?" do
    def stats(measurable_count:, total_lag:, max_lag:)
      obj = Object.new
      obj.define_singleton_method(:measurable_count) { measurable_count }
      obj.define_singleton_method(:total_lag) { total_lag }
      obj.define_singleton_method(:max_lag) { max_lag }
      obj
    end

    it "is not skewed when the lag is evenly spread" do
      # [1_000, 1_000, 1_000] -> others average 1_000, max is 1x that
      refute(skewed?(stats(measurable_count: 3, total_lag: 3_000, max_lag: 1_000)))
    end

    it "is skewed when the lag is concentrated on one partition" do
      # [9_100, 300, 300, 300] -> others average 300, well over the default 3x threshold
      assert(skewed?(stats(measurable_count: 4, total_lag: 10_000, max_lag: 9_100)))
    end

    it "is skewed when one partition carries all of the lag of a two-partition topic" do
      # The case the self-inclusive average could never flag: [100_000, 0] has an overall average
      # of 50_000, so max/avg is 2 and the default 3x threshold was unreachable no matter how
      # lopsided the split. Against the other partition (0) it is unambiguously skewed.
      assert(skewed?(stats(measurable_count: 2, total_lag: 100_000, max_lag: 100_000)))
    end

    it "is not skewed with fewer than two measurable partitions" do
      refute(skewed?(stats(measurable_count: 1, total_lag: 10_000, max_lag: 10_000)))
    end

    it "is not skewed when there is no lag at all" do
      refute(skewed?(stats(measurable_count: 3, total_lag: 0, max_lag: 0)))
    end

    it "is not skewed when the biggest lag is below the minimum" do
      # [90, 1, 1, 1] is lopsided, but 90 is below the default 100 minimum, so it is just noise
      refute(skewed?(stats(measurable_count: 4, total_lag: 93, max_lag: 90)))
    end

    it "is not skewed when the imbalance is below the threshold" do
      # [2_400, 1_800, 1_800] -> others average 1_800, max is 1.33x that, below the default 3x
      refute(skewed?(stats(measurable_count: 3, total_lag: 6_000, max_lag: 2_400)))
    end

    context "when the skew threshold is lowered via config" do
      before { ::Karafka::Web.config.ui.health.lags.skew_threshold = 2 }

      after { ::Karafka::Web.config.ui.health.lags.skew_threshold = 3 }

      it "flags a distribution that the default threshold leaves alone" do
        # [4_000, 1_000, 1_000] -> others average 1_000, max is 4x that
        assert(skewed?(stats(measurable_count: 3, total_lag: 6_000, max_lag: 4_000)))
      end
    end

    context "when the skew minimum is raised via config" do
      before { ::Karafka::Web.config.ui.health.lags.skew_minimum = 100_000 }

      after { ::Karafka::Web.config.ui.health.lags.skew_minimum = 100 }

      it "does not flag a distribution whose biggest lag is below the raised minimum" do
        refute(skewed?(stats(measurable_count: 4, total_lag: 10_000, max_lag: 9_100)))
      end
    end
  end

  describe "#topic_lag_status_row" do
    # `topic_lag_status_row` classifies on `avg_lag` and calls the real `skewed?`, which reads
    # `measurable_count`/`total_lag`/`max_lag` - so the stub exposes both. `total_lag` defaults to
    # `avg_lag * measurable_count` so the numbers stay a self-consistent distribution. The defaults
    # describe an unskewed topic.
    def topic_stub(avg_lag:, max_lag: 0, measurable_count: 1, total_lag: nil)
      total_lag ||= avg_lag * measurable_count

      obj = Object.new
      obj.define_singleton_method(:avg_lag) { avg_lag }
      obj.define_singleton_method(:max_lag) { max_lag }
      obj.define_singleton_method(:measurable_count) { measurable_count }
      obj.define_singleton_method(:total_lag) { total_lag }
      obj
    end

    # An unskewed topic with a low average lag (below the warning threshold)
    def healthy_stub
      topic_stub(avg_lag: 10)
    end

    # [9_000, 100, 100, 100]: skewed (max is 90x the 100 others-average) while the 2_325 average
    # stays below the warning threshold, so only the skew can produce a status here
    def skewed_stub
      topic_stub(avg_lag: 2_325, max_lag: 9_000, measurable_count: 4, total_lag: 9_300)
    end

    it "flags high average lag as an error" do
      assert_equal("status-row-error", topic_lag_status_row(topic_stub(avg_lag: 10_000)))
    end

    it "flags medium average lag as a warning" do
      assert_equal("status-row-warning", topic_lag_status_row(topic_stub(avg_lag: 5_000)))
    end

    it "flags a skewed topic as a warning even when the average lag is low" do
      assert_equal("status-row-warning", topic_lag_status_row(skewed_stub))
    end

    it "flags a topic with paused partitions as a warning even when the average lag is low" do
      assert_equal("status-row-warning", topic_lag_status_row(healthy_stub, paused: true))
    end

    it "keeps error precedence over a skew warning" do
      # [40_000, 0]: avg_lag 20_000 is a high-lag error, and it is genuinely skewed too, so this
      # asserts the error wins over the skew warning
      assert_equal(
        "status-row-error",
        topic_lag_status_row(
          topic_stub(avg_lag: 20_000, max_lag: 40_000, measurable_count: 2, total_lag: 40_000)
        )
      )
    end

    it "returns no class for a healthy topic" do
      assert_equal("", topic_lag_status_row(healthy_stub))
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
