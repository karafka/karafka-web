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
  let(:lrj_warn1) { "Manual pause/resume operations are not supported" }
  let(:lrj_warn2) { "Cannot Manage Long-Running Job Partitions Pausing" }
  let(:cannot_perform) { "This Operation Cannot Be Performed" }
  let(:not_active) { "Consumer pauses can only be managed using Web UI when" }
  let(:not_paused) { "Pause settings can only be configured for partitions" }
  let(:form) { "<form" }
  let(:card_detail) { "card-detail-container" }

  before do
    topics_config.consumers.states.name = states_topic
    topics_config.consumers.reports.name = reports_topic
    topics_config.consumers.commands.name = commands_topic

    produce(states_topic, Fixtures.consumers_states_file)
    produce(reports_topic, Fixtures.consumers_reports_file)
  end

  describe "#new" do
    let(:new_path) do
      [
        "consumers",
        "partitions",
        consumer_group_id,
        topic_name,
        partition_id,
        "pause",
        "new"
      ].join("/")
    end

    before { get(new_path) }

    context "when a process exists and is running" do
      it "expect to include relevant details" do
        assert_predicate(response, :ok?)
        assert_includes(body, consumer_group_id)
        assert_includes(body, topic_name)
        assert_includes(body, partition_id.to_s)
        assert_includes(body, "Pause Duration:")
        assert_includes(body, "Safety Check:")
        assert_includes(body, form)
        assert_includes(body, card_detail)
        refute_includes(body, lrj_warn1)
        refute_includes(body, lrj_warn2)
        refute_includes(body, cannot_perform)
        refute_includes(body, not_active)
      end
    end

    context "when a process exists, is running but topic is lrj" do
      before do
        # Capture let values for use inside routes.draw block
        cg_id = consumer_group_id
        t_name = topic_name

        # Add routing for the consumer group and topic so LRJ detection works
        Karafka::App.routes.draw do
          consumer_group cg_id do
            topic t_name do
              consumer Class.new(Karafka::BaseConsumer)
              long_running_job true
            end
          end
        end

        get(new_path)
      end

      it "expect to include relevant details" do
        assert_predicate(response, :ok?)
        assert_includes(body, consumer_group_id)
        assert_includes(body, topic_name)
        assert_includes(body, partition_id.to_s)
        assert_includes(body, lrj_warn1)
        assert_includes(body, lrj_warn2)
        refute_includes(body, "Pause Duration:")
        refute_includes(body, "Safety Check:")
        refute_includes(body, form)
        refute_includes(body, cannot_perform)
        refute_includes(body, not_active)
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

        get(new_path)
      end

      it "expect to show not running error message" do
        assert_predicate(response, :ok?)
        assert_includes(body, cannot_perform)
        assert_includes(body, not_active)
        refute_includes(body, form)
      end
    end
  end

  describe "#create" do
    let(:duration) { 60 }
    let(:prevent_override) { "on" }
    let(:post_path) do
      [
        "consumers",
        "partitions",
        consumer_group_id,
        topic_name,
        partition_id,
        "pause"
      ].join("/")
    end

    before do
      post(
        post_path,
        duration: duration,
        prevent_override: prevent_override
      )
    end

    context "when a process exists and is running" do
      it "expect to redirect with success message" do
        assert_equal(302, response.status)
        expect(flash[:success]).to include(
          "Initiated pause for partition #{topic_name}##{partition_id}"
        )
      end

      it "expect to create pause command with correct parameters" do
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
        assert_equal(partition_id, command[:partition_id])
        assert_equal(duration * 1_000, command[:duration])
        assert_equal(true, command[:prevent_override])
        assert_equal("partitions.pause", command[:name])

        matchers = message.payload.fetch(:matchers)
        assert_equal(consumer_group_id, matchers[:consumer_group_id])
        assert_equal(topic_name, matchers[:topic])
        assert_equal(partition_id, matchers[:partition_id])
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
  end

  describe "#edit" do
    let(:edit_path) do
      [
        "consumers",
        "partitions",
        consumer_group_id,
        topic_name,
        partition_id,
        "pause",
        "edit"
      ].join("/")
    end

    before { get(edit_path) }

    context "when a process exists and is running and partition is not paused" do
      it "expect to include relevant details" do
        assert_predicate(response, :ok?)
        assert_includes(body, consumer_group_id)
        assert_includes(body, topic_name)
        assert_includes(body, partition_id.to_s)
        assert_includes(body, not_paused)
        refute_includes(body, form)
        refute_includes(body, "Reset Counter:")
        refute_includes(body, "Resume Processing")
        refute_includes(body, lrj_warn1)
        refute_includes(body, lrj_warn2)
        refute_includes(body, cannot_perform)
        refute_includes(body, not_active)
      end
    end

    context "when a process exists and is running and partition is paused" do
      before do
        report = Fixtures.consumers_reports_json
        sg = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        sg[:topics][:default][:partitions][:"0"][:poll_state] = "paused"

        produce(reports_topic, report.to_json)

        get(edit_path)
      end

      it "expect to include relevant details" do
        assert_predicate(response, :ok?)
        assert_includes(body, consumer_group_id)
        assert_includes(body, topic_name)
        assert_includes(body, partition_id.to_s)
        assert_includes(body, "Reset Counter:")
        assert_includes(body, "Resume Processing")
        assert_includes(body, form)
        refute_includes(body, not_paused)
        refute_includes(body, lrj_warn1)
        refute_includes(body, lrj_warn2)
        refute_includes(body, cannot_perform)
        refute_includes(body, not_active)
      end
    end

    context "when a process exists, is running but topic is lrj" do
      before do
        # Capture let values for use inside routes.draw block
        cg_id = consumer_group_id
        t_name = topic_name

        # Add routing for the consumer group and topic so LRJ detection works
        Karafka::App.routes.draw do
          consumer_group cg_id do
            topic t_name do
              consumer Class.new(Karafka::BaseConsumer)
              long_running_job true
            end
          end
        end

        get(edit_path)
      end

      it "expect to include relevant details" do
        assert_predicate(response, :ok?)
        assert_includes(body, consumer_group_id)
        assert_includes(body, topic_name)
        assert_includes(body, partition_id.to_s)
        assert_includes(body, lrj_warn1)
        assert_includes(body, lrj_warn2)
        refute_includes(body, not_paused)
        refute_includes(body, "Reset Counter:")
        refute_includes(body, "Resume Processing")
        refute_includes(body, form)
        refute_includes(body, cannot_perform)
        refute_includes(body, not_active)
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
        assert_includes(body, cannot_perform)
        assert_includes(body, not_active)
        refute_includes(body, form)
      end
    end
  end

  describe "#delete" do
    let(:reset_attempts) { "yes" }
    let(:delete_path) do
      [
        "consumers",
        "partitions",
        consumer_group_id,
        topic_name,
        partition_id,
        "pause"
      ].join("/")
    end

    before do
      delete(
        delete_path,
        reset_attempts: reset_attempts
      )
    end

    context "when a process exists and is running" do
      it "expect to redirect with success message" do
        assert_equal(302, response.status)
        expect(flash[:success]).to include(
          "Initiated resume for partition #{topic_name}##{partition_id}"
        )
      end

      it "expect to create resume command with correct parameters" do
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
        assert_equal(partition_id, command[:partition_id])
        assert_equal(true, command[:reset_attempts])
        assert_equal("partitions.resume", command[:name])

        matchers = message.payload.fetch(:matchers)
        assert_equal(consumer_group_id, matchers[:consumer_group_id])
        assert_equal(topic_name, matchers[:topic])
        assert_equal(partition_id, matchers[:partition_id])
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
  end
end
