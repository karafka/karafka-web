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

  let(:no_processes) { "There Are No Karafka Consumer Processes" }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe "#index" do
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
        assert_body('title="Supported only with standalone consumer processes"')
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
        assert_body('title="Supported only with standalone consumer processes"')
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
end
