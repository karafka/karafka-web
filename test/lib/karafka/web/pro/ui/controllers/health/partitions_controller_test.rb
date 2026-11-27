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

  context "when the consumer group id needs encoding in the path" do
    let(:group_id) { "my group/a?b#c-zażółć" }
    let(:encoded_group_id) { URI.encode_uri_component(group_id) }
    let(:topic_path) { "/health/topics/#{encoded_group_id}/default" }

    def produce_group_report(poll_state: "active")
      topics_config.consumers.reports.name = reports_topic

      report = Fixtures.consumers_reports_json(symbolize_names: false)
      consumer_group = report["consumer_groups"].delete("example_app6_app")
      consumer_group["id"] = group_id
      report["consumer_groups"][group_id] = consumer_group
      report.dig(partition_scope[0], group_id, *partition_scope[2..])["poll_state"] = poll_state

      produce(reports_topic, report.to_json, key: report["process"]["id"])
    end

    before do
      produce_group_report

      Karafka::Admin.stubs(:read_lags_with_offsets).returns(
        group_id => { "default" => { 0 => { lag: 4_200, offset: 10 } } }
      )
    end

    it "expect every lens tab and breadcrumb link to render the topic of that group" do
      get "#{topic_path}/overview"

      assert_ok

      %w[overview lags offsets changes].each do |lens|
        assert_body(%(href="#{topic_path}/#{lens}"))

        get "#{topic_path}/#{lens}"

        assert_ok
        assert_body("Topic default in #{group_id}")
      end

      assert_body(%(href="#{topic_path}/cluster_lags"))

      get "#{topic_path}/cluster_lags"

      assert_ok
      assert_body("4200")
    end

    it "expect the topic and lens breadcrumbs to link to the topic of that group" do
      get "#{topic_path}/lags"

      crumbs = body[%r{<div class="breadcrumbs">.*?</ul>}m]

      assert_includes(crumbs, %(href="#{topic_path}/overview"))
      assert_includes(crumbs, %(href="#{topic_path}/lags"))
    end

    context "when commanding is on" do
      let(:commands_topic) { create_topic }

      before do
        Karafka::Web.config.commanding.active = true
        topics_config.consumers.commands.name = commands_topic
      end

      it "expect the pause and offset links and forms to reach that group" do
        {
          "/consumers/topics/#{encoded_group_id}/default/pause" => [:post, "new", { duration: 60 }],
          "/consumers/partitions/#{encoded_group_id}/default/0/pause" => [:post, "new", { duration: 60 }],
          "/consumers/partitions/#{encoded_group_id}/default/0/offset" => [:put, "edit", { offset: 1 }]
        }.each do |action_path, (verb, page, params)|
          get "#{topic_path}/overview"

          assert_body(%(href="#{action_path}/#{page}"))

          get "#{action_path}/#{page}"

          assert_ok
          assert_body(%(action="#{action_path}"))

          public_send(verb, action_path, params)

          assert_equal(302, response.status)
          assert_includes(flash[:success], group_id)
        end
      end

      context "when the partition is paused" do
        before { produce_group_report(poll_state: "paused") }

        it "expect the resume links and forms to reach that group" do
          [
            "/consumers/topics/#{encoded_group_id}/default/pause",
            "/consumers/partitions/#{encoded_group_id}/default/0/pause"
          ].each do |action_path|
            get "#{topic_path}/overview"

            assert_body(%(href="#{action_path}/edit"))

            get "#{action_path}/edit"

            assert_ok
            assert_body(%(action="#{action_path}"))

            delete(action_path, reset_attempts: "on")

            assert_equal(302, response.status)
            assert_includes(flash[:success], group_id)
          end
        end
      end
    end

    it "expect the group breadcrumb to scope the topics list to the decoded group id" do
      get "#{topic_path}/overview"

      assert_body(
        %(href="/health/topics?filter[field]=consumer_group&filter[value]=#{Rack::Utils.escape(group_id)}")
      )
    end

    it "expect a bare topic path to redirect to the overview of that group" do
      get topic_path

      assert_equal(302, response.status)
      assert_equal("#{topic_path}/overview", response.headers["location"])
    end
  end

  %w[%zz abc%].each do |malformed|
    context "when the consumer group id is a malformed escape (#{malformed})" do
      it do
        [
          "/health/topics/#{malformed}/default/overview",
          "/consumers/topics/#{malformed}/default/pause/new",
          "/consumers/partitions/#{malformed}/default/0/pause/new",
          "/consumers/partitions/#{malformed}/default/0/offset/edit"
        ].each do |path|
          env = Rack::MockRequest.env_for("http://example.org/")
          env["PATH_INFO"] = path

          assert_equal(404, app.call(env).first)
        end
      end
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
      assert_body("Pause all partitions of this topic within the")
      refute_body("Commanding is disabled in the Web UI configuration")
    end

    it "expect the resume actions to be disabled when nothing is paused" do
      assert_body('class="btn btn-success btn-sm btn-disabled"')
      assert_body('title="No partitions of this topic are paused"')
      assert_body('title="This partition is not paused"')
      refute_body("pause/edit")
    end

    context "when commanding is disabled" do
      before do
        Karafka::Web.config.commanding.active = false

        get "health/topics/example_app6_app/default/overview"
      end

      it "expect the pause action to be disabled with the reason" do
        assert_ok
        assert_body('class="btn btn-warning btn-sm btn-disabled"')
        refute_body("pause/new")
        assert_body('title="Commanding is disabled in the Web UI configuration"')
      end
    end

    context "when sorted" do
      before { get "health/topics/example_app6_app/default/overview?sort=id+desc" }

      it { assert_ok }

      it "expect only the partition header to be marked as sorted" do
        assert_body("Partition&nbsp;&#9662;")
        assert_body("Process ID&nbsp;&#x21D5;")
      end
    end

    context "when sorted by process id and partitions belong to different processes" do
      before do
        topics_config.consumers.reports.name = reports_topic

        # Partition 0 belongs to shinra:2:2 and partition 1 to shinra:1:1, so the partition id
        # order is the opposite of the process id order
        [["shinra:2:2", 0], ["shinra:1:1", 1]].each do |process_id, partition_id|
          report = Fixtures.consumers_reports_json(symbolize_names: false)
          report["process"]["id"] = process_id

          topic_data = report.dig(*partition_scope[0..5])
          partition = topic_data["partitions"].delete("0")
          partition["id"] = partition_id
          topic_data["partitions"][partition_id.to_s] = partition
          topic_data["partitions_cnt"] = 2

          produce(reports_topic, report.to_json, key: process_id)
        end

        get "health/topics/example_app6_app/default/overview?sort=process_id+asc"
      end

      it "expect rows in process id order and only the process id header marked as sorted" do
        assert_ok

        first = body.index("consumers/shinra:1:1/subscriptions")
        second = body.index("consumers/shinra:2:2/subscriptions")

        assert_operator(first, :<, second)
        assert_body("Process ID&nbsp;&#9652;")
        assert_body("Partition&nbsp;&#x21D5;")
      end
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

      it "expect the resume actions to be available" do
        assert_body("default/pause/edit")
        assert_body("0/pause/edit")
        refute_body("No partitions of this topic are paused")
        refute_body("This partition is not paused")
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

      it "expect the consumer group to link to its cluster consumer group page" do
        assert_ok
        assert_body("health/consumer_groups/example_app6_app")
      end

      context "when deleting offsets is allowed" do
        before do
          Karafka::Web.config.ui.policies.consumer_groups.stubs(:delete_offsets?).returns(true)

          get "health/topics/example_app6_app/default/cluster_lags"
        end

        it "expect the deletion to be on the consumer group topics page, not here" do
          assert_ok
          refute_body("Delete Offsets")
          refute_body("/delete")
        end
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
