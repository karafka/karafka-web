# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("No health data is available")
      end
    end

    context "when data is present" do
      before { get "health/overview" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("Not available until first offset")
        assert_body("327355")
      end

      context "when sorted" do
        before { get "health/overview?sort=id+desc" }

        it { assert(response.ok?) }
      end

      context "when commanding is enabled" do
        before do
          Karafka::Web.config.commanding.active = true

          get "health/overview"
        end

        it "expect to show topic pause controls without disabled state" do
          assert(response.ok?)
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
          assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when data is present" do
      before { get "health/lags" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when we have groups and data but topics never consumed" do
      before { get "health/lags" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("-1")
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when data is present" do
      before { get "health/offsets" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("No health data is available")
        refute_body("badge-warning")
        refute_body("badge-error")
      end
    end

    context "when data is present" do
      before { get "health/changes" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
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
        assert(response.ok?)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
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
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("Until manual resume")
      end
    end
  end
end
