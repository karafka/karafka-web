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

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }
  let(:consumer_group_id) { "example_app6_app" }
  let(:topic_name) { "default" }
  let(:partition_id) { 0 }
  let(:commands_topic) { create_topic }
  let(:form) { "<form" }

  before do
    topics_config.consumers.states.name = states_topic
    topics_config.consumers.reports.name = reports_topic
    topics_config.consumers.commands.name = commands_topic

    produce(states_topic, Fixtures.consumers_states_file)
    produce(reports_topic, Fixtures.consumers_reports_file)
  end

  describe "#edit" do
    let(:edit_path) do
      [
        "consumers",
        "partitions",
        consumer_group_id,
        topic_name,
        partition_id,
        "offset",
        "edit"
      ].join("/")
    end

    before { get(edit_path) }

    context "when a process exists and is running" do
      it "expect to include relevant details" do
        assert_predicate(response, :ok?)
        assert_includes(body, consumer_group_id)
        assert_includes(body, topic_name)
        assert_includes(body, partition_id.to_s)
        assert_includes(body, "New Offset:")
        assert_includes(body, "Prevent Overtaking:")
        assert_includes(body, "Resume Immediately:")
        assert_includes(body, "checkbox")
        assert_includes(body, "Adjust Offset")
        assert_includes(body, form)
        assert_includes(body, "Offset Edit")
        assert_includes(body, "High Offset:")
        assert_includes(body, "Low Offset:")
        assert_includes(body, "EOF Offset:")
        assert_includes(body, "Committed Offset:")
        assert_includes(body, "Stored Offset:")
        assert_includes(body, "Lag:")
        assert_includes(body, "Running Consumer Process Operation")
        assert_includes(body, "Takes effect during the next poll operation")
        assert_includes(body, "May affect message processing")
        refute_includes(body, "This Operation Cannot Be Performed")
      end
    end

    context "when consumer group does not exist" do
      let(:consumer_group_id) { "not-existing" }

      it { assert_equal(404, status) }
    end

    context "when topic is not correct" do
      let(:topic_name) { "not-existing" }

      it { assert_equal(404, status) }
    end

    context "when partition does not exist" do
      let(:partition_id) { 100 }

      it { assert_equal(404, status) }
    end

    context "when no process is running" do
      before do
        report = Fixtures.consumers_reports_json
        report[:process][:status] = "stopped"
        produce(reports_topic, report.to_json)

        get(edit_path)
      end

      it "expect to show not running error message" do
        assert_predicate(response, :ok?)
        assert_includes(body, "This Operation Cannot Be Performed")
        assert_includes(body, "Consumer offsets can only be modified using Web UI when the")
        refute_includes(body, form)
      end
    end
  end

  describe "#update" do
    let(:offset) { 100 }
    let(:prevent_overtaking) { "no" }
    let(:force_resume) { "on" }
    let(:post_path) do
      [
        "consumers",
        "partitions",
        consumer_group_id,
        topic_name,
        partition_id,
        "offset"
      ].join("/")
    end

    before do
      put(
        post_path,
        offset: offset,
        prevent_overtaking: prevent_overtaking,
        force_resume: force_resume
      )
    end

    it "expect to redirect with success message" do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_includes(flash[:success], "Initiated offset adjustment to #{offset}")
    end

    it "expect to create new command in the given topic with matchers" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first

      # Commands are broadcast to all processes, so no key
      assert_nil(message.key)
      assert_equal("1.2.0", message.payload[:schema_version])
      assert_equal("request", message.payload[:type])
      assert_match(/\A[0-9a-f-]{36}\z/, message.payload[:id])
      refute_nil(message.payload[:dispatched_at])

      command = message.payload.fetch(:command)

      assert_equal(consumer_group_id, command[:consumer_group_id])
      assert_equal(topic_name, command[:topic])
      assert_equal(0, command[:partition_id])
      assert_equal(offset, command[:offset])
      assert_equal(false, command[:prevent_overtaking])
      assert_equal(true, command[:force_resume])
      assert_equal("partitions.seek", command[:name])

      matchers = message.payload.fetch(:matchers)
      assert_equal(consumer_group_id, matchers[:consumer_group_id])
      assert_equal(topic_name, matchers[:topic])
      assert_equal(partition_id, matchers[:partition_id])
    end
  end
end
