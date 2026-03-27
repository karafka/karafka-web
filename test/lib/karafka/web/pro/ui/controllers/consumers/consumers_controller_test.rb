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

  let(:no_processes) { "There Are No Karafka Consumer Processes" }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe "#index" do
    context "when we open a consumers root" do
      before { get "consumers" }

      it "expect to redirect to overview page" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "consumers/overview")
      end
    end

    context "when the state data is missing" do
      before do
        topics_config.consumers.states.name = states_topic

        get "consumers/overview"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are no active consumers" do
      before do
        topics_config.consumers.reports.name = states_topic

        get "consumers/overview"
      end

      it do
        refute_body("Pro Feature")
        assert(response.ok?)
        refute_body(support_message)
        assert_body(breadcrumbs)
        refute_body(pagination)
        assert_body(no_processes)
      end
    end

    context "when commanding is disabled" do
      before do
        Karafka::Web.config.commanding.active = false

        get "consumers/overview"
      end

      after { Karafka::Web.config.commanding.active = true }

      it do
        assert(response.ok?)
        assert_body("Commands")
        assert_body("Controls")
        refute_body("Pro Feature")
      end

      it "expect to show Controls and Commands tabs in disabled state" do
        assert_body("disabled btn-disabled")
      end
    end

    context "when commanding is enabled" do
      before do
        Karafka::Web.config.commanding.active = true

        get "consumers/overview"
      end

      it do
        assert(response.ok?)
        assert_body("Controls")
        assert_body("Commands")
      end

      it "expect to show Controls and Commands tabs without disabled state" do
        refute_body("disabled btn-disabled")
      end
    end

    context "when there are active consumers" do
      before { get "consumers/overview" }

      it do
        assert(response.ok?)
        refute_body(support_message)
        assert_body(breadcrumbs)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body("246 MB")
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("2690818651.82293")
      end

      context "when sorting" do
        before { get "consumers/overview?sort=id+desc" }

        it { assert(response.ok?) }
      end
    end

    context "when there are active consumers with many partitions assigned" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        scope = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        base = scope[:topics][:default][:partitions]

        50.times { |i| base[i + 1] = base[:"0"].dup.merge(id: i + 1) }

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get "consumers/overview"
      end

      it do
        assert(response.ok?)
        assert_body("0-50")
        assert_body("default-[0-50] (51 partitions total)")
        refute_body(support_message)
        assert_body(breadcrumbs)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body("246 MB")
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("2690818651.82293")
      end
    end

    context "when there are active consumers reported in a transactional fashion" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "consumers/overview"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        assert_body(breadcrumbs)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body("246 MB")
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("2690818651.82293")
      end
    end

    context "when there are more consumers that we fit in a single page" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        100.times do |i|
          id = "shinra:#{i}:#{i}"

          data["processes"][id] = {
            dispatched_at: 2_690_818_669.526_218,
            offset: i
          }

          report = base_report.dup
          report["process"]["id"] = id

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, data.to_json)
      end

      context "when we visit first page" do
        before { get "consumers/overview" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(50, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end

      context "when we visit second page" do
        before { get "consumers/overview?page=2" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body("shinra:32:32")
          assert_body("shinra:34:34")
          assert_body("shinra:35:35")
          assert_body("shinra:35:35")
          assert_equal(50, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end

      context "when we go beyond available pages" do
        before { get "consumers/overview?page=100" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(no_meaningful_results)
          assert_equal(0, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end
    end
  end

  describe "#performance" do
    context "when the state data is missing" do
      before do
        topics_config.consumers.states.name = states_topic

        get "consumers/performance"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are no active consumers" do
      before do
        topics_config.consumers.reports.name = states_topic

        get "consumers/performance"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body(no_processes)
      end
    end

    context "when commanding is enabled" do
      before do
        Karafka::Web.config.commanding.active = true

        get "consumers/performance"
      end

      it do
        assert(response.ok?)
        assert_body("Controls")
        assert_body("Commands")
      end
    end

    context "when there are active consumers" do
      before { get "consumers/performance" }

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("RSS")
        assert_body("ID")
        assert_body("Utilization")
        assert_body("Threads")
        assert_body("120 MB")
        assert_body("5.6%")
      end

      context "when sorting" do
        before { get "consumers/performance?sort=id+desc" }

        it { assert(response.ok?) }
      end
    end

    context "when there are active consumers reported in a transactional fashion" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "consumers/performance"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("RSS")
        assert_body("ID")
        assert_body("Utilization")
        assert_body("Threads")
        assert_body("120 MB")
        assert_body("5.6%")
      end
    end

    context "when there are more consumers that we fit in a single page" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        100.times do |i|
          id = "shinra:#{i}:#{i}"

          data["processes"][id] = {
            dispatched_at: 2_690_818_669.526_218,
            offset: i
          }

          report = base_report.dup
          report["process"]["id"] = id

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, data.to_json)
      end

      context "when we visit first page" do
        before { get "consumers/performance" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(50, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end

      context "when we visit second page" do
        before { get "consumers/performance?page=2" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body("shinra:32:32")
          assert_body("shinra:34:34")
          assert_body("shinra:35:35")
          assert_body("shinra:35:35")
          assert_equal(50, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end

      context "when we go beyond available pages" do
        before { get "consumers/performance?page=100" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(no_meaningful_results)
          assert_equal(0, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end
    end
  end

  describe "#controls" do
    context "when the state data is missing" do
      before do
        topics_config.consumers.states.name = states_topic

        get "consumers/controls"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are no active consumers" do
      before do
        topics_config.consumers.reports.name = states_topic

        get "consumers/controls"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body(no_processes)
      end
    end

    context "when there are active consumers" do
      before { get "consumers/controls" }

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("running")
        assert_body("ID")
        assert_body("Performance")
        assert_body("Quiet All")
        assert_body("Stop All")
        assert_body("Trace")
      end

      context "when sorting" do
        before { get "consumers/controls?sort=id+desc" }

        it { assert(response.ok?) }
      end
    end

    context "when there are active embedded consumers" do
      before do
        topics_config.consumers.reports.name = reports_topic

        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        10.times do |i|
          id = "shinra:#{i}:#{i}"

          report = base_report.dup
          report["process"]["execution_mode"] = "embedded"

          produce(reports_topic, report.to_json, key: id)
        end

        get "consumers/controls"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("running")
        assert_body("ID")
        assert_body("Performance")
        assert_body("Quiet All")
        assert_body("Stop All")
        assert_body("Trace")
        assert_body('title="Supported only in standalone consumer processes"')
      end

      context "when sorting" do
        before { get "consumers/controls?sort=id+desc" }

        it { assert(response.ok?) }
      end
    end

    context "when there are active swarm consumers" do
      before do
        topics_config.consumers.reports.name = reports_topic

        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        10.times do |i|
          id = "shinra:#{i}:#{i}"

          report = base_report.dup
          report["process"]["execution_mode"] = "swarm"

          produce(reports_topic, report.to_json, key: id)
        end

        get "consumers/controls"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("running")
        assert_body("ID")
        assert_body("Performance")
        assert_body("Quiet All")
        assert_body("Stop All")
        assert_body("Trace")
        assert_body('title="Supported only in standalone consumer processes"')
      end

      context "when sorting" do
        before { get "consumers/controls?sort=id+desc" }

        it { assert(response.ok?) }
      end
    end

    context "when there are active consumers reported in a transactional fashion" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "consumers/controls"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_processes)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("shinra:1:1")
        assert_body("/consumers/shinra:1:1/subscriptions")
        assert_body("running")
        assert_body("ID")
        assert_body("Performance")
        assert_body("Quiet All")
        assert_body("Stop All")
        assert_body("Trace")
      end
    end

    context "when there are more consumers that we fit in a single page" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        100.times do |i|
          id = "shinra:#{i}:#{i}"

          data["processes"][id] = {
            dispatched_at: 2_690_818_669.526_218,
            offset: i
          }

          report = base_report.dup
          report["process"]["id"] = id

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, data.to_json)
      end

      context "when we visit first page" do
        before { get "consumers/controls" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body("shinra:0:0")
          assert_body("shinra:1:1")
          assert_body("shinra:11:11")
          assert_body("shinra:12:12")
          assert_equal(125, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end

      context "when we visit second page" do
        before { get "consumers/controls?page=2" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body("shinra:32:32")
          assert_body("shinra:34:34")
          assert_body("shinra:35:35")
          assert_body("shinra:35:35")
          assert_equal(125, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end

      context "when we go beyond available pages" do
        before { get "consumers/controls?page=100" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(no_meaningful_results)
          assert_equal(0, body.scan("shinra:").size)
          refute_body(support_message)
        end
      end
    end
  end

  describe "#details" do
    context "when details exist" do
      before { get "consumers/shinra:1:1/details" }

      it do
        assert(response.ok?)
        assert_body('<code class="json p-0 m-0"')
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when commanding is enabled" do
      before do
        Karafka::Web.config.commanding.active = true

        get "consumers/shinra:1:1/details"
      end

      it do
        assert(response.ok?)
        assert_body("Trace")
        assert_body("Quiet")
        assert_body("Stop")
      end
    end

    context "when commanding is disabled" do
      before do
        Karafka::Web.config.commanding.active = false

        get "consumers/shinra:1:1/details"
      end

      after { Karafka::Web.config.commanding.active = true }

      it do
        assert(response.ok?)
        assert_body("btn-lockable  btn-disabled")
        assert_body("Trace")
        assert_body("Quiet")
        assert_body("Stop")
      end
    end

    context "when trying to visit details of a process with incompatible schema" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        report[:schema_version] = "100.0"
        produce(reports_topic, report.to_json)

        get "consumers/shinra:1:1/details"
      end

      it do
        assert_equal(404, response.status)
      end
    end

    context "when details exist written in a transactional fashion" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "consumers/shinra:1:1/details"
      end

      it do
        assert(response.ok?)
        assert_body('<code class="json p-0 m-0"')
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when given process does not exist" do
      before { get "consumers/4e8f7174ae53/details" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end
  end

  describe "jobs/ path redirect" do
    context "when visiting the jobs/ path without type indicator" do
      before { get "consumers/shinra:1:1/jobs" }

      it "expect to redirect to running jobs page" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "consumers/shinra:1:1/jobs/running")
      end
    end
  end

  describe "#subscriptions" do
    context "when subscriptions exist" do
      before { get "consumers/shinra:1:1/subscriptions" }

      it do
        assert(response.ok?)
        assert_body("Rebalance count")
        assert_body("This process does not consume any")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when subscription has an unknown rebalance reason" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: true)

        sg = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        sg[:state][:rebalance_reason] = ""

        produce(reports_topic, report.to_json)

        get "consumers/shinra:1:1/subscriptions"
      end

      it do
        assert(response.ok?)
        assert_body("Rebalance count")
        assert_body("Unknown")
        assert_body("This process does not consume any")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when subscriptions exist and was reported in a transactional fashion" do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get "consumers/shinra:1:1/subscriptions"
      end

      it do
        assert(response.ok?)
        assert_body("Rebalance count")
        assert_body("This process does not consume any")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when trying to visit subscriptions of a process with incompatible schema" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        report[:schema_version] = "100.0"
        produce(reports_topic, report.to_json)

        get "consumers/shinra:1:1/subscriptions"
      end

      it do
        assert_equal(404, response.status)
      end
    end

    context "when given process has no subscriptions at all" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report["consumer_groups"] = {}

        produce(reports_topic, report.to_json)

        get "consumers/shinra:1:1/subscriptions"
      end

      it do
        assert(response.ok?)
        assert_body("This process is not subscribed to any topics")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when given process does not exist" do
      before do
        topics_config.consumers.reports.name = reports_topic

        get "consumers/4e8f7174ae53/subscriptions"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when subscription group has a static membership instance_id" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Set instance_id on the subscription group
        sg = report["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        sg["instance_id"] = "my-static-member-456"

        produce(reports_topic, report.to_json)

        get "consumers/shinra:1:1/subscriptions"
      end

      it do
        assert(response.ok?)
        assert_body("my-static-member-456")
        assert_body("Static Membership ID")
        assert_body("tooltip")
        assert_body("Consumer Group")
        assert_body("Subscription Group")
      end
    end

    context "when subscription group does not have static membership" do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Ensure instance_id is false (no static membership) on all subscription groups
        # across all consumer groups
        report["consumer_groups"].each_value do |cg|
          cg["subscription_groups"].each_value do |sg|
            sg["instance_id"] = false
          end
        end

        produce(reports_topic, report.to_json)

        get "consumers/shinra:1:1/subscriptions"
      end

      it do
        assert(response.ok?)
        refute_body("Static Membership ID")
        # Tooltips for consumer group and subscription group should still be present
        assert_body("Consumer Group")
        assert_body("Subscription Group")
      end
    end

    context "when commanding is enabled" do
      before do
        Karafka::Web.config.commanding.active = true

        get "consumers/shinra:1:1/subscriptions"
      end

      it "expect to show partition edit options without disabled state" do
        assert(response.ok?)
        refute_body("btn-info btn-sm btn-disabled")
        refute_body("btn-warning btn-sm btn-disabled")
      end
    end

    context "when commanding is disabled" do
      before do
        Karafka::Web.config.commanding.active = false

        get "consumers/shinra:1:1/subscriptions"
      end

      after { Karafka::Web.config.commanding.active = true }

      it "expect to show partition edit options in disabled state" do
        assert(response.ok?)
        assert_body("btn-info btn-sm btn-disabled")
        assert_body("btn-warning btn-sm btn-disabled")
      end
    end
  end
end
