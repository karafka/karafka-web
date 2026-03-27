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

  let(:schedules_topic) { create_topic }
  let(:logs_topic) { create_topic }
  let(:not_operable) { "Recurring Tasks Data Unavailable" }
  let(:no_logs) { "There are no available logs." }

  before do
    topics = Karafka::App.config.recurring_tasks.topics
    topics.schedules.name = schedules_topic
    topics.logs.name = logs_topic

    draw_routes do
      recurring_tasks(true)
    end
  end

  describe "#schedule" do
    context "when schedules topic does not exist" do
      let(:schedules_topic) { generate_topic_name }
      let(:logs_topic) { generate_topic_name }

      before { get "recurring_tasks/schedule" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body(not_operable)
      end
    end

    context "when schedules topic exists but there is no data" do
      before { get "recurring_tasks/schedule" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(not_operable)
        refute_body(pagination)
        refute_body(support_message)
        refute_body("Schedule 1.0.0")
      end
    end

    context "when schedules topic exists but there are only commands recently and no state" do
      before do
        produce_many(schedules_topic, Array.new(50, ""))

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(not_operable)
        refute_body("Schedule 1.0.0")
      end
    end

    context "when state is the most recent message and its of an empty cron" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("empty"),
          key: "state:schedule"
        )

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(not_operable)
        assert_body("Schedule 1.0.0")
      end
    end

    context "when state is behind other messages but reachable" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("empty"),
          key: "state:schedule"
        )

        produce_many(schedules_topic, Array.new(15, ""))

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(not_operable)
        assert_body("Schedule 1.0.0")
      end
    end

    context "when state is behind other messages and not reachable" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("empty"),
          key: "state:schedule"
        )

        produce_many(schedules_topic, Array.new(50, ""))

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(not_operable)
        refute_body("Schedule 1.0.0")
      end
    end

    context "when state has only disabled tasks that were never running" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("only_disabled_never_running"),
          key: "state:schedule"
        )

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Never")
        assert_body("* * * * *")
        assert_body("*/2 * * *")
        assert_body("Disabled")
        assert_body("status-row-warning text-muted")
        assert_body("btn btn-warning btn-sm btn-disabled")
        assert_body("Schedule 1.0.1")
        refute_body(not_operable)
        refute_body('<time class="ltr" dir="ltr"')
      end
    end

    context "when state has only disabled tasks that were running" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("only_disabled_running"),
          key: "state:schedule"
        )

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Never")
        assert_body("* * * * *")
        assert_body("*/2 * * *")
        assert_body("Disabled")
        assert_body('<time class="ltr" dir="ltr"')
        assert_body("status-row-warning text-muted")
        assert_body("btn btn-warning btn-sm btn-disabled")
        assert_body("Schedule 1.0.1")
        refute_body(not_operable)
      end
    end

    context "when state has only enabled tasks that were running" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("only_enabled"),
          key: "state:schedule"
        )

        get "recurring_tasks/schedule"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("* * * * *")
        assert_body("*/2 * * *")
        assert_body("Enabled")
        assert_body('<time class="ltr" dir="ltr"')
        assert_body("Schedule 1.0.1")
        refute_body("btn btn-warning btn-sm btn-disabled")
        refute_body("status-row-warning text-muted")
        refute_body("Never")
        refute_body(not_operable)
      end
    end

    context "when sorting" do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg("only_enabled"),
          key: "state:schedule"
        )

        get "recurring_tasks/schedule?sort=enabled+desc"
      end

      it "expect not to crash" do
        assert(response.ok?)
      end
    end
  end

  describe "#logs" do
    context "when logs topic does not exist" do
      let(:schedules_topic) { generate_topic_name }
      let(:logs_topic) { generate_topic_name }

      before { get "recurring_tasks/logs" }

      it do
        assert_equal(404, response.status)
      end
    end

    context "when there are no logs" do
      before { get "recurring_tasks/logs" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(no_logs)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when there are few successful logs only" do
      before do
        log = Fixtures.recurring_tasks_logs_msg("success")
        produce_many(logs_topic, Array.new(10, log))

        get "recurring_tasks/logs"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("test1")
        assert_body("1.0.1")
        assert_body('<span class="badge  badge-success">Success</span>')
        refute_body(no_logs)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when there are few failed logs only" do
      before do
        log = Fixtures.recurring_tasks_logs_msg("failed")
        produce_many(logs_topic, Array.new(10, log))

        get "recurring_tasks/logs"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("test2")
        assert_body("1.0.1")
        assert_body('<span class="badge  badge-error">Error</span>')
        refute_body(no_logs)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when there are many mixed logs on many pages" do
      before do
        failed = Fixtures.recurring_tasks_logs_msg("failed")
        success = Fixtures.recurring_tasks_logs_msg("success")
        logs = [failed, success] * 25
        produce_many(logs_topic, logs)

        get "recurring_tasks/logs"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("test1")
        assert_body("test2")
        assert_body("1.0.1")
        assert_body('<span class="badge  badge-error">Error</span>')
        assert_body(pagination)
        refute_body(no_logs)
        refute_body(support_message)
      end
    end

    context "when we fetch second offset-based page" do
      before do
        failed = Fixtures.recurring_tasks_logs_msg("failed")
        success = Fixtures.recurring_tasks_logs_msg("success")
        logs = [failed, success] * 25
        produce_many(logs_topic, logs)

        get "recurring_tasks/logs?offset=25"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("test1")
        assert_body("test2")
        assert_body("1.0.1")
        assert_body('<span class="badge  badge-error">Error</span>')
        assert_body(pagination)
        refute_body(no_logs)
        refute_body(support_message)
      end
    end
  end

  describe "#trigger_all" do
    before { post "recurring_tasks/trigger_all" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
    end

    it "expect to create new command" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first

      assert_equal("command:trigger:*", message.key)
      assert_equal("command", message.payload[:type])
      assert_equal("trigger", message.payload[:command][:name])
      assert_equal("*", message.payload[:task][:id])
    end
  end

  describe "#disable_all" do
    before { post "recurring_tasks/disable_all" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
    end

    it "expect to create new command" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first

      assert_equal("command:disable:*", message.key)
      assert_equal("command", message.payload[:type])
      assert_equal("disable", message.payload[:command][:name])
      assert_equal("*", message.payload[:task][:id])
    end
  end

  describe "#enable_all" do
    before { post "recurring_tasks/enable_all" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
    end

    it "expect to create new command" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first

      assert_equal("command:enable:*", message.key)
      assert_equal("command", message.payload[:type])
      assert_equal("enable", message.payload[:command][:name])
      assert_equal("*", message.payload[:task][:id])
    end
  end

  describe "#enable" do
    before { post "recurring_tasks/task1/enable" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
    end

    it "expect to create new command" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first

      assert_equal("command:enable:task1", message.key)
      assert_equal("command", message.payload[:type])
      assert_equal("enable", message.payload[:command][:name])
      assert_equal("task1", message.payload[:task][:id])
    end
  end

  describe "#disable" do
    before { post "recurring_tasks/task1/disable" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
    end

    it "expect to create new command" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first

      assert_equal("command:disable:task1", message.key)
      assert_equal("command", message.payload[:type])
      assert_equal("disable", message.payload[:command][:name])
      assert_equal("task1", message.payload[:task][:id])
    end
  end

  describe "#trigger" do
    before { post "recurring_tasks/task1/trigger" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
    end

    it "expect to create new command" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first

      assert_equal("command:trigger:task1", message.key)
      assert_equal("command", message.payload[:type])
      assert_equal("trigger", message.payload[:command][:name])
      assert_equal("task1", message.payload[:task][:id])
    end
  end
end
