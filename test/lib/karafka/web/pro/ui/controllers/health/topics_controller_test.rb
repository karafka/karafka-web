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

    context "when visiting a consumer group path without a topic" do
      before { get "health/topics/example_app6_app" }

      it "expect to redirect to the topics list scoped to that consumer group" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "health/topics")
        assert_includes(response.headers["location"], "consumer_group")
        assert_includes(response.headers["location"], "example_app6_app")
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

      it "expect a high-lag topic to get the error row border" do
        # the default topic's average lag (213_731_273) is well above the high-lag threshold
        assert_ok
        assert_body("status-row-error")
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

      # `lag_hybrid` is sortable only for the topics view (index action), not for cluster_lags.
      # `default` has a huge lag while `visits` has none, so a working sort must flip their
      # positions between asc and desc - proving the index action resolves the topics-view sort
      # attributes (and not the cluster_lags ones).
      context "when sorted by lag_hybrid, a topics-view-only sortable attribute" do
        def overview_position(topic)
          response.body.index("health/topics/example_app6_app/#{topic}/overview")
        end

        it "expect the sort to actually apply for the index action" do
          get "health/topics?sort=lag_hybrid+desc"

          assert_ok
          # default (213_731_273) comes before visits (0) when descending
          assert(overview_position("default") < overview_position("visits"))

          get "health/topics?sort=lag_hybrid+asc"

          assert_ok
          # ...and after it when ascending
          assert(overview_position("default") > overview_position("visits"))
        end
      end

      # `lag` is a cluster_lags-only sortable attribute; the topics view has no such column, so
      # asking for it must be ignored gracefully (no error) rather than honored.
      context "when sorted by lag, a cluster_lags-only sortable attribute" do
        before { get "health/topics?sort=lag+desc" }

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

    context "when a paused topic is not otherwise lagging" do
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

        get "health/topics"
      end

      it "expect the paused topic row to use the warning border" do
        assert_ok
        assert_body("status-row-warning")
        refute_body("status-row-error")
      end
    end

    context "when a topic's lag is skewed across its partitions" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        topic_data = report.dig(*partition_scope[0..5])
        base_partition = report.dig(*partition_scope)

        # One hot partition (9_100) and three small ones (300 each): avg 2_500, max 9_100 -> more
        # than 3x the average (skewed), but the average is below the high-lag error threshold
        base_partition["lag"] = 9_100
        base_partition["lag_stored"] = 9_100

        (1..3).each do |id|
          partition = base_partition.dup
          partition["id"] = id
          partition["lag"] = 300
          partition["lag_stored"] = 300
          topic_data["partitions"][id.to_s] = partition
        end

        topic_data["partitions_cnt"] = 4

        produce(reports_topic, report.to_json)

        get "health/topics"
      end

      it "expect the skewed topic row to show the skew badge and the warning border" do
        assert_ok
        assert_body("skewed")
        assert_body("status-row-warning")
        # The aggregation rolls the four partitions up: total 10_000 and biggest single lag 9_100
        assert_body("10000")
        assert_body("9100")
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

      # `lag` is sortable only for the cluster_lags action, not for the topics view. orders (9100)
      # and visits (5) must flip positions between asc and desc for the sort to be applied -
      # proving the cluster_lags action resolves the cluster_lags sort attributes.
      context "when sorted by lag, a cluster_lags-only sortable attribute" do
        def cluster_position(topic)
          response.body.index("health/topics/example_app6_app/#{topic}/cluster_lags")
        end

        it "expect the sort to actually apply for the cluster_lags action" do
          Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)

          get "health/cluster_lags?sort=lag+asc"

          assert_ok
          # visits (5) comes before orders (9100) when ascending
          assert(cluster_position("visits") < cluster_position("orders"))

          get "health/cluster_lags?sort=lag+desc"

          assert_ok
          # ...and after it when descending
          assert(cluster_position("visits") > cluster_position("orders"))
        end
      end

      # `paused_count` is a topics-view-only sortable attribute; the cluster_lags rows have no such
      # column, so asking for it must be ignored gracefully rather than error out.
      context "when sorted by paused_count, a topics-view-only sortable attribute" do
        before do
          Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
          get "health/cluster_lags?sort=paused_count+desc"
        end

        it { assert_ok }
      end
    end

    context "when a cluster topic's lag is skewed across its partitions" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(
          "example_app6_app" => {
            "orders" => {
              0 => { lag: 9_100, offset: 1 },
              1 => { lag: 300, offset: 1 },
              2 => { lag: 300, offset: 1 },
              3 => { lag: 300, offset: 1 }
            }
          }
        )

        get "health/cluster_lags"
      end

      it "expect the skewed cluster topic row to show the skew badge and warning border" do
        assert_ok
        assert_body("skewed")
        assert_body("status-row-warning")
        # total 10_000 across the four partitions, biggest single lag 9_100
        assert_body("10000")
        assert_body("9100")
      end
    end

    context "when sorted by topic name" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
        get "health/cluster_lags?sort=name+desc"
      end

      it { assert_ok }
    end

    # Health views do not paginate (aggregating per topic is the scaling strategy), so a large
    # number of topics must all render on one page without any silent truncation.
    context "when there are many topics" do
      before do
        many = (0...30).to_h { |i| ["many-topic-#{i}", { 0 => { lag: i, offset: i } }] }
        Karafka::Admin.stubs(:read_lags_with_offsets).returns("example_app6_app" => many)
        get "health/cluster_lags"
      end

      it "expect to render every topic with no pagination" do
        assert_ok
        # first and last topics both render -> nothing was truncated to a page
        assert_body("many-topic-0")
        assert_body("many-topic-29")
        refute_body(pagination)
      end
    end

    context "when filtering by a matching topic" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
        get_filtered("health/cluster_lags", topic: "orders")
      end

      it do
        assert_ok
        assert_body("orders")
        assert_body("9100")
        refute_body("visits")
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

    context "when filtering by the consumer group" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
        get_filtered("health/cluster_lags", consumer_group: "example_app6_app")
      end

      it do
        assert_ok
        assert_body("orders")
        assert_body("9100")
      end
    end

    context "when filtering by a non-matching consumer group" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(cluster_lags)
        get_filtered("health/cluster_lags", consumer_group: "no-such-group")
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

    context "when a routed consumer group has real lag on a real topic" do
      let(:lagging_topic) { create_topic }
      let(:lagging_group) { "it-cluster-lags-#{SecureRandom.uuid}" }

      before do
        # Real messages advance the high watermark to 100
        produce_many(lagging_topic, Array.new(100) { SecureRandom.uuid })

        # Route the topic under our group so the active-topics cluster lag read picks it up
        group = lagging_group
        topic_name = lagging_topic
        draw_routes do
          consumer_group group do
            topic topic_name do
              consumer Karafka::BaseConsumer
            end
          end
        end

        # Commit the group behind the watermark to create a real, known lag (100 - 40 = 60)
        Karafka::Admin.seek_consumer_group(lagging_group, lagging_topic => { 0 => 40 })

        get "health/cluster_lags"
      end

      it "reads and renders the real lag straight from the cluster (no stubbing)" do
        assert_ok
        # The real topic reaches the aggregated view with its real lag (100 - 40)
        assert_body(lagging_topic)
        assert_body("60")
        # ...and drills into its per-partition cluster lags lens
        assert_body("health/topics/#{lagging_group}/#{lagging_topic}/cluster_lags")
      end
    end
  end
end
