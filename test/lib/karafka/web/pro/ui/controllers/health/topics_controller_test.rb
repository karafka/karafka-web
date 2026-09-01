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

  describe "health/ path redirect" do
    context "when visiting the health/ path without a sub-page" do
      before { get "health" }

      it "expect to redirect to the aggregated topics page" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "health/topics")
      end
    end
  end

  describe "legacy top-level per-partition paths" do
    # The old all-topics per-partition views are gone; their paths redirect to the aggregated
    # topics view so existing links/bookmarks keep working.
    %w[overview lags offsets changes].each do |lens|
      context "when visiting the legacy health/#{lens} path" do
        before { get "health/#{lens}" }

        it "expect to redirect to the aggregated topics page" do
          assert_equal(302, response.status)
          assert_includes(response.headers["location"], "health/topics")
        end
      end
    end
  end

  describe "#index" do
    context "when no report data" do
      before do
        topics_config.consumers.reports.name = reports_topic
        get "health/topics"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("No health data is available")
        # The top-level tabs are limited to Topics and Cluster Lags
        assert_body("health/topics")
        assert_body("health/cluster_lags")
      end
    end

    context "when data is present" do
      before { get "health/topics" }

      it "expect to render one aggregated row per topic" do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("example_app6_app")
        assert_body("default")
        assert_body("test2")
        assert_body("visits")
        # Aggregated total (and, for the single-partition default topic, avg) lag
        assert_body("213731273")
        # Healthy topic: active LSO risk state and no paused partitions
        assert_body("all active")
        refute_body("badge-error")
      end

      it "expect each topic name to link to its per-topic overview lens" do
        assert_ok
        assert_body("health/topics/example_app6_app/default/overview")
      end

      it "expect the old top-level per-partition views to no longer be linked" do
        assert_ok
        # The old all-topics per-partition tabs/links are gone (they are per-topic now)
        refute_body("health/overview")
        refute_body("health/lags")
        refute_body("health/offsets")
        refute_body("health/changes")
      end

      context "when sorted by an aggregate column" do
        before { get "health/topics?sort=max_lag+desc" }

        it { assert_ok }
      end

      context "when sorted by topic name" do
        before { get "health/topics?sort=name+desc" }

        it { assert_ok }
      end
    end

    context "when filtering by a matching topic keyword" do
      before { get_filtered("health/topics", "default") }

      it do
        assert_ok
        assert_body("default")
        assert_body("213731273")
        refute_body("visits")
        assert_body('name="filter[value]"')
        assert_body('value="default"')
      end
    end

    context "when filtering by a non-matching keyword" do
      before { get_filtered("health/topics", "this-topic-does-not-exist") }

      it do
        assert_ok
        assert_body("No results match your filter")
        assert_body('name="filter[value]"')
        refute_body("213731273")
      end
    end

    context "when scoping the filter to the topic field" do
      context "when the topic matches" do
        before { get_filtered("health/topics", topic: "default") }

        it do
          assert_ok
          assert_body("default")
          assert_body("213731273")
          refute_body("visits")
          assert_body('value="topic" selected')
        end
      end

      context "when the topic does not match" do
        before { get_filtered("health/topics", topic: "no-such-topic") }

        it do
          assert_ok
          assert_body("No results match your filter")
          refute_body("213731273")
        end
      end
    end

    context "when scoping the filter to the consumer group field" do
      context "when the consumer group matches" do
        before { get_filtered("health/topics", consumer_group: "example_app6_app") }

        it do
          assert_ok
          assert_body("example_app6_app")
          assert_body("default")
          assert_body("213731273")
        end
      end

      context "when the consumer group does not match" do
        before { get_filtered("health/topics", consumer_group: "no-such-group") }

        it do
          assert_ok
          assert_body("No results match your filter")
          refute_body("213731273")
        end
      end
    end

    context "when some partitions have no data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = 3

        produce(reports_topic, report.to_json)

        get "health/topics"
      end

      it "expect to flag the partitions with no data" do
        assert_ok
        # partitions 1 and 2 have no data
        assert_body("2 no data")
        assert_body("badge-warning")
      end
    end

    context "when one of the partitions is at risk due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        partition_data["committed_offset"] = 1_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics"
      end

      it "expect the aggregated row to escalate to at_risk" do
        assert_ok
        assert_body("at_risk")
        assert_body("badge-warning")
        refute_body("stopped")
        refute_body("badge-error")
      end
    end

    context "when one of the partitions is stopped due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        partition_data["committed_offset"] = 3_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics"
      end

      it "expect the aggregated row to escalate to stopped" do
        assert_ok
        assert_body("stopped")
        assert_body("badge-error")
        refute_body("at_risk")
      end
    end

    context "when one of the partitions is paused" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)
        partition_data["poll_state"] = "paused"
        partition_data["poll_state_ch"] = 1_000_000_000_000

        produce(reports_topic, report.to_json)

        get "health/topics"
      end

      it "expect the aggregated row to report the paused partition" do
        assert_ok
        assert_body("1 paused")
      end
    end

    context "when data is present but reported in a transactional fashion" do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "health/topics"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("default")
        assert_body("213731273")
      end
    end
  end

  describe "#cluster_lags" do
    let(:cluster_lags) do
      {
        "example_app6_app" => {
          "orders" => {
            0 => { lag: 100, offset: 5 },
            1 => { lag: 9_000, offset: 10 }
          },
          "visits" => {
            0 => { lag: 5, offset: 1 }
          }
        }
      }
    end

    context "when no report data" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns({})
        get "health/cluster_lags"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("No health data is available")
      end
    end

    context "when data is present" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
        get "health/cluster_lags"
      end

      it "expect to render one aggregated row per topic" do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("orders")
        assert_body("visits")
        # Aggregated total lag for orders (100 + 9000)
        assert_body("9100")
        # Biggest single-partition lag is surfaced
        assert_body("9000")
      end

      it "expect each topic to drill down into the per-topic cluster lags lens" do
        assert_ok
        assert_body("health/topics/example_app6_app/orders/cluster_lags")
      end

      context "when sorted by an aggregate column" do
        before do
          Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
          get "health/cluster_lags?sort=max_lag+desc"
        end

        it { assert_ok }
      end
    end

    context "when filtering by a non-matching topic" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
        get_filtered("health/cluster_lags", topic: "zzz-no-such-topic")
      end

      it do
        assert_ok
        assert_body("No results match your filter")
        refute_body("9100")
      end
    end
  end

  # These exercise the real `Karafka::Admin.read_lags_with_offsets` path end to end against the
  # test cluster (no mocking), so a regression in the actual cluster lag fetch/aggregation is caught.
  describe "#cluster_lags against the real cluster (no mocking)" do
    context "when listing the aggregated cluster lags" do
      before { get "health/cluster_lags" }

      it do
        assert_ok
        assert_body(breadcrumbs)
      end
    end
  end
end
