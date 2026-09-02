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
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:reports_topic) { create_topic }

  let(:partition_scope) do
    %w[
      consumer_groups
      example_app6_app
      subscription_groups
      c4ca4238a0b9_0
      topics
      default
      partitions
      0
    ]
  end

  context "when visiting a topic without a lens" do
    before { get "health/topics/example_app6_app/default" }

    it "expect to redirect to the overview lens" do
      assert_equal(302, response.status)
      assert_includes(response.headers["location"], "health/topics/example_app6_app/default/overview")
    end
  end

  describe "#overview" do
    before { get "health/topics/example_app6_app/default/overview" }

    it "expect to render the per-partition overview for that topic" do
      assert_ok
      assert_body(breadcrumbs)
      refute_body(pagination)
      # The single partition of the default topic, with its lag and stored offset
      assert_body("213731273")
      assert_body("327355")
      # The per-topic lens sub-tabs are present, including the per-topic cluster lags lens
      assert_body("health/topics/example_app6_app/default/lags")
      assert_body("health/topics/example_app6_app/default/offsets")
      assert_body("health/topics/example_app6_app/default/changes")
      assert_body("health/topics/example_app6_app/default/cluster_lags")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/overview?sort=id+desc" }

      it { assert_ok }
    end

    it "expect a high-lag partition row to use the error border (lag wins over process status)" do
      # the default partition's lag (213_731_273) is well above the high-lag threshold
      assert_ok
      assert_body("status-row-error")
      refute_body("status-row-running")
    end

    context "when the partition lag is at the warning level (not yet an error)" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        # 6_000 is above the warning threshold (5_000) but below the error one (10_000)
        partition_data["lag"] = 6_000
        partition_data["lag_stored"] = 6_000

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/overview"
      end

      it "expect the partition row to use the yellow warning border, not the red error one" do
        assert_ok
        assert_body("status-row-warning")
        refute_body("status-row-error")
      end
    end

    it "expect the breadcrumb to place the topic within its consumer group" do
      # Topics are always viewed within a consumer group, so the trail is
      # Health > <group> > Topics > <topic> > <lens>. The group crumb links to the topics list
      # scoped to that consumer group (a link unique to the breadcrumb on this page).
      assert_ok
      assert_body("filter[field]=consumer_group&filter[value]=example_app6_app")
      # the last crumb is the current lens (overview here)
      assert_body("Overview")
    end

    context "when a partition has no committed offsets yet" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        # Negative values mean "not available yet" and must render as N/A, not as -1
        partition_data["lag"] = -1
        partition_data["lag_stored"] = -1
        partition_data["stored_offset"] = -1
        partition_data["committed_offset"] = -1

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/overview"
      end

      it "expect the unavailable lag and offset cells to render N/A" do
        assert_ok
        assert_body("N/A")
      end
    end

    context "when some assigned partitions have no data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        # Only partition 0 is reported, but the topic has 3 partitions -> 1 and 2 fall back
        topic_data["partitions_cnt"] = 3

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/overview"
      end

      it "expect a no-data fallback row for each missing partition" do
        assert_ok
        assert_body("No data available")
      end
    end

    context "when the partition is paused and not otherwise lagging" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        # Drop the lag so it does not force an error border, then pause the partition
        partition_data["lag"] = 0
        partition_data["lag_stored"] = 0
        partition_data["poll_state"] = "paused"
        partition_data["poll_state_ch"] = 1_000_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/overview"
      end

      it "expect the paused partition row to use the warning border" do
        assert_ok
        assert_body("status-row-warning")
        refute_body("status-row-error")
      end
    end

    # The per-partition tables do not paginate, so a topic with many partitions must render every
    # partition row on one page (from the consumer reports).
    context "when the topic has many partitions" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        base_partition = report.dig(*partition_scope)

        (1...30).each do |id|
          partition = base_partition.dup
          partition["id"] = id
          # distinctive per-partition lag so we can assert first/last rows render
          partition["lag_stored"] = 900_000 + id
          topic_data["partitions"][id.to_s] = partition
        end

        topic_data["partitions_cnt"] = 30

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/overview"
      end

      it "expect to render every partition row with no pagination" do
        assert_ok
        assert_body("900001")
        assert_body("900029")
        refute_body(pagination)
      end
    end

    context "when the topic does not exist" do
      before { get "health/topics/example_app6_app/no-such-topic/overview" }

      it { assert_equal(404, status) }
    end

    context "when the consumer group does not exist" do
      before { get "health/topics/no-such-group/default/overview" }

      it { assert_equal(404, status) }
    end
  end

  describe "#lags" do
    before { get "health/topics/example_app6_app/default/lags" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("213731273")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/lags?sort=lag+desc" }

      it { assert_ok }
    end

    context "when the topic does not exist" do
      before { get "health/topics/example_app6_app/no-such-topic/lags" }

      it { assert_equal(404, status) }
    end

    context "when the consumer group does not exist" do
      before { get "health/topics/no-such-group/default/lags" }

      it { assert_equal(404, status) }
    end
  end

  describe "#offsets" do
    before { get "health/topics/example_app6_app/default/offsets" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("327355")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/offsets?sort=committed_offset+desc" }

      it { assert_ok }
    end

    context "when the partition is at risk due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        partition_data["committed_offset"] = 1_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/offsets"
      end

      it do
        assert_ok
        assert_body("at_risk")
        assert_body("badge-warning")
        refute_body("stopped")
      end
    end

    context "when the partition is stopped due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        # Committed caught up to a frozen last stable offset -> stopped (not just at risk)
        partition_data["committed_offset"] = 3_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics/example_app6_app/default/offsets"
      end

      it do
        assert_ok
        assert_body("stopped")
        assert_body("badge-error")
        refute_body("at_risk")
      end
    end

    context "when the topic does not exist" do
      before { get "health/topics/example_app6_app/no-such-topic/offsets" }

      it { assert_equal(404, status) }
    end

    context "when the consumer group does not exist" do
      before { get "health/topics/no-such-group/default/offsets" }

      it { assert_equal(404, status) }
    end
  end

  describe "#changes" do
    before { get "health/topics/example_app6_app/default/changes" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("Pause state change")
      # The lens ends the breadcrumb trail with its own label
      assert_body("Changes")
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/changes?sort=poll_state_ch+desc" }

      it { assert_ok }
    end

    context "when the topic does not exist" do
      before { get "health/topics/example_app6_app/no-such-topic/changes" }

      it { assert_equal(404, status) }
    end

    context "when the consumer group does not exist" do
      before { get "health/topics/no-such-group/default/changes" }

      it { assert_equal(404, status) }
    end
  end

  describe "#cluster_lags" do
    context "when the topic has cluster lag data" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(
          "example_app6_app" => {
            "default" => {
              0 => { lag: 4_200, offset: 10 }
            }
          }
        )

        get "health/topics/example_app6_app/default/cluster_lags"
      end

      it "expect to render the per-partition cluster lags for that topic" do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("4200")
      end

      context "when sorted" do
        before do
          Karafka::Admin.stubs(:read_lags_with_offsets).returns(
            "example_app6_app" => {
              "default" => {
                0 => { lag: 4_200, offset: 10 }
              }
            }
          )

          get "health/topics/example_app6_app/default/cluster_lags?sort=lag+desc"
        end

        it { assert_ok }
      end
    end

    context "when the topic is reported but has no cluster lag data" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns({})
        get "health/topics/example_app6_app/default/cluster_lags"
      end

      it "expect to render an empty table (not a 404) for a real reported topic" do
        assert_ok
        assert_body(breadcrumbs)
      end
    end

    context "when the topic exists nowhere (no cluster lags and not reported)" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns({})
        get "health/topics/example_app6_app/no-such-topic/cluster_lags"
      end

      it { assert_equal(404, status) }
    end

    # The per-partition tables do not paginate, so a topic with many partitions must render every
    # partition row on one page.
    context "when the topic has many partitions" do
      before do
        partitions = (0...30).to_h { |id| [id, { lag: 900_000 + id, offset: id }] }
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(
          "example_app6_app" => { "default" => partitions }
        )

        get "health/topics/example_app6_app/default/cluster_lags"
      end

      it "expect to render every partition row with no pagination" do
        assert_ok
        # the first and last partitions' (distinctive) lags both render
        assert_body("900000")
        assert_body("900029")
        refute_body(pagination)
      end
    end
  end
end
