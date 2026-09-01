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

  describe "#overview" do
    context "when no report data" do
      before do
        topics_config.consumers.reports.name = reports_topic
        get "health/overview"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("No health data is available")
      end
    end

    context "when data is present" do
      before { get "health/overview" }

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("327355")
      end

      context "when sorted" do
        before { get "health/overview?sort=id+desc" }

        it { assert_ok }
      end

      context "when filtering by a matching topic name" do
        before { get_filtered("health/overview", "default") }

        it do
          assert_ok
          # The matching topic and its data are preserved (match-propagation keeps the branch)
          assert_body("default")
          assert_body("327355")
          # The filtering box is rendered with a field selector and the active keyword
          assert_body('name="filter[value]"')
          assert_body('name="filter[field]"')
          assert_body('value="default"')
        end
      end

      context "when filtering by a non-matching keyword" do
        before { get_filtered("health/overview", "this-topic-does-not-exist") }

        it do
          assert_ok
          # The filter pruned everything, so we show the filter-specific empty state (not the
          # misleading "no data / no processes" one), while still offering the filter box
          assert_body("No results match your filter")
          assert_body('name="filter[value]"')
          refute_body("327355")
        end
      end

      context "when scoping the filter to the topic field" do
        context "when the topic matches" do
          before { get_filtered("health/overview", topic: "default") }

          it do
            assert_ok
            assert_body("default")
            assert_body("327355")
            assert_body('value="topic" selected')
          end
        end

        context "when the topic does not match" do
          before { get_filtered("health/overview", topic: "no-such-topic") }

          it do
            assert_ok
            assert_body("No results match your filter")
            refute_body("327355")
          end
        end
      end

      context "when scoping the filter to the consumer group field" do
        context "when the consumer group matches" do
          before { get_filtered("health/overview", consumer_group: "example_app6_app") }

          it do
            assert_ok
            # The whole group (its topics) is kept
            assert_body("example_app6_app")
            assert_body("default")
            assert_body("327355")
          end
        end

        context "when the consumer group does not match" do
          before { get_filtered("health/overview", consumer_group: "no-such-group") }

          it do
            assert_ok
            assert_body("No results match your filter")
            refute_body("327355")
          end
        end
      end

      context "when commanding is enabled" do
        before do
          Karafka::Web.config.commanding.active = true

          get "health/overview"
        end

        it "expect to show topic pause controls without disabled state" do
          assert_ok
          assert_body("Pause All")
          refute_body("btn-warning btn-sm btn-disabled")
        end

        it "expect to show partition edit options without disabled state" do
          refute_body("btn-info btn-sm btn-disabled")
        end
      end

      context "when commanding is disabled" do
        before do
          Karafka::Web.config.commanding.active = false

          get "health/overview"
        end

        after { Karafka::Web.config.commanding.active = true }

        it "expect to show topic pause controls in disabled state" do
          assert_ok
          assert_body("Pause All")
          assert_body("btn-warning btn-sm btn-disabled")
        end

        it "expect to show partition edit options in disabled state" do
          assert_body("btn-info btn-sm btn-disabled")
        end
      end
    end

    context "when some partitions have no data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Set partitions_cnt to 3 but only keep partition 0 data
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = 3

        produce(reports_topic, report.to_json)

        get "health/overview"
      end

      it do
        assert_ok
        assert_body("No data available")
        assert_equal(2, body.scan("No data available").size) # partitions 1 and 2
      end
    end

    context "when all partitions data matches partitions_cnt" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Ensure partitions_cnt matches actual partition count
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = topic_data["partitions"].keys.length

        produce(reports_topic, report.to_json)

        get "health/overview"
      end

      it do
        assert_ok
        refute_body("No data available")
      end
    end

    context "when subscription group has a static membership instance_id" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Set instance_id on the subscription group
        sg = report.dig(*partition_scope[0..3])
        sg["instance_id"] = "my-static-member-id-123"

        produce(reports_topic, report.to_json)

        get "health/overview"
      end

      it do
        assert_ok
        assert_body("my-static-member-id-123")
        assert_body("Static Membership ID")
      end
    end

    context "when subscription group does not have static membership" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Ensure instance_id is false (no static membership)
        sg = report.dig(*partition_scope[0..3])
        sg["instance_id"] = false

        produce(reports_topic, report.to_json)

        get "health/overview"
      end

      it do
        assert_ok
        refute_body("Static Membership ID")
      end
    end

    context "when data is present but written in a transactional fashion" do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "health/overview"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("327355")
      end
    end
  end

  describe "#lags" do
    context "when no report data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        get "health/lags"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when data is present" do
      before { get "health/lags" }

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("213731273")
        refute_body("badge-error")
      end
    end

    context "when some partitions have no data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = 3

        produce(reports_topic, report.to_json)

        get "health/lags"
      end

      it do
        assert_ok
        assert_body("No data available")
        assert_equal(2, body.scan("No data available").size)
      end
    end

    context "when all partitions data matches partitions_cnt" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = topic_data["partitions"].keys.length

        produce(reports_topic, report.to_json)

        get "health/lags"
      end

      it do
        assert_ok
        refute_body("No data available")
      end
    end

    context "when data is present but reported in a transactional fashion" do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "health/lags"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("213731273")
        refute_body("badge-error")
      end
    end
  end

  describe "#cluster_lags" do
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
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when we have groups and data but topics never consumed" do
      before { get "health/lags" }

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("-1")
      end
    end

    context "when filtering by a non-matching topic" do
      before { get_filtered("health/cluster_lags", topic: "zzz-no-such-topic") }

      it do
        assert_ok
        # The filter emptied the tree, so we show the filter-specific empty state, not the
        # misleading "no data / no processes running" message
        assert_body("No results match your filter")
        refute_body("No health data is available")
      end
    end
  end

  describe "#offsets" do
    context "when no report data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        get "health/offsets"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when data is present" do
      before { get "health/offsets" }

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("327355")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when some partitions have no data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = 3

        produce(reports_topic, report.to_json)

        get "health/offsets"
      end

      it do
        assert_ok
        assert_body("No data available")
        assert_equal(2, body.scan("No data available").size)
      end
    end

    context "when all partitions data matches partitions_cnt" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = topic_data["partitions"].keys.length

        produce(reports_topic, report.to_json)

        get "health/offsets"
      end

      it do
        assert_ok
        refute_body("No data available")
      end
    end

    context "when data is present but reported in a transactional fashion" do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "health/offsets"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("327355")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when one of partitions is at risk due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)

        partition_data["committed_offset"] = 1_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/offsets"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("badge-warning")
        assert_body("at_risk")
        refute_body("badge-error")
        refute_body("stopped")
      end
    end

    context "when one of partitions is stopped due to LSO" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)

        partition_data["committed_offset"] = 3_000
        partition_data["ls_offset"] = 3_000
        partition_data["ls_offset_fd"] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get "health/offsets"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Not available until first offset")
        assert_body("badge-error")
        assert_body("stopped")
        refute_body("at_risk")
        refute_body("badge-warning")
      end
    end
  end

  describe "#changes" do
    context "when no report data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        get "health/changes"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when data is present" do
      before { get "health/changes" }

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Pause state change")
        assert_body("N/A")
        assert_body("2690818656.575513")
      end
    end

    context "when some partitions have no data" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = 3

        produce(reports_topic, report.to_json)

        get "health/changes"
      end

      it do
        assert_ok
        assert_body("No data available")
        assert_equal(2, body.scan("No data available").size)
      end
    end

    context "when all partitions data matches partitions_cnt" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        topic_data = report.dig(*partition_scope[0..5])
        topic_data["partitions_cnt"] = topic_data["partitions"].keys.length

        produce(reports_topic, report.to_json)

        get "health/changes"
      end

      it do
        assert_ok
        refute_body("No data available")
      end
    end

    context "when data is present but reported in a transactional fashion" do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "health/changes"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Pause state change")
        assert_body("Changes")
      end
    end

    context "when one of partitions is paused forever" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)

        partition_data["poll_state"] = "paused"
        partition_data["poll_state_ch"] = 1_000_000_000_000

        produce(reports_topic, report.to_json)

        get "health/changes"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body("Until manual resume")
      end
    end
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

  describe "#topics" do
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
        # The Topics tab is present and highlighted
        assert_body("health/topics")
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
        # Aggregated total lag of the single default partition
        assert_body("213731273")
        # Healthy topic: active LSO risk state and no paused partitions
        assert_body("all active")
        refute_body("badge-error")
      end

      it "expect each topic name to link to its per-topic detail page" do
        assert_ok
        assert_body("health/topics/example_app6_app/default")
      end

      context "when sorted" do
        before { get "health/topics?sort=id+desc" }

        it { assert_ok }
      end
    end

    context "when filtering by a matching topic keyword" do
      before { get_filtered("health/topics", "default") }

      it do
        assert_ok
        assert_body("default")
        assert_body("213731273")
        # The non-matching topics are pruned
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

      it "expect to flag the incomplete partition coverage" do
        assert_ok
        assert_body("1/3")
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
        refute_body("all active")
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

  describe "#topic" do
    context "when the consumer group and topic exist" do
      before { get "health/topics/example_app6_app/default" }

      it "expect to render the per-partition detail for that topic" do
        assert_ok
        assert_body(breadcrumbs)
        refute_body(pagination)
        # The per-partition overview table is reused for the drill-down
        assert_body("327355")
        assert_body("Not available until first offset")
        # Breadcrumb and title carry the topic name
        assert_body("default")
      end

      context "when sorted" do
        before { get "health/topics/example_app6_app/default?sort=id+desc" }

        it { assert_ok }
      end
    end

    context "when the topic does not exist" do
      before { get "health/topics/example_app6_app/no-such-topic" }

      it { assert_equal(404, status) }
    end

    context "when the consumer group does not exist" do
      before { get "health/topics/no-such-group/default" }

      it { assert_equal(404, status) }
    end
  end
end
