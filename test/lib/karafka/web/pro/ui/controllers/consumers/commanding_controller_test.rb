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

  let(:commands_topic) { create_topic }
  let(:process_id) { SecureRandom.uuid }

  before { topics_config.consumers.commands.name = commands_topic }

  describe "#trace" do
    before { post "consumers/commanding/#{process_id}/trace" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
      assert_includes(flash[:success], "The Trace command has been dispatched to the")
    end

    it "expect to create new command in the given topic with process_id matcher" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      assert_nil(message.key)
      assert_equal("1.2.0", message.payload[:schema_version])
      assert_equal("request", message.payload[:type])
      refute_nil(message.payload[:dispatched_at])
      assert_equal({name: "consumers.trace"}, message.payload[:command])
      assert_equal({process_id: process_id}, message.payload[:matchers])
    end
  end

  describe "#quiet" do
    before { post "consumers/commanding/#{process_id}/quiet" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
      assert_includes(flash[:success], "The Quiet command has been dispatched to the")
    end

    it "expect to create new command in the given topic with process_id matcher" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      assert_nil(message.key)
      assert_equal("1.2.0", message.payload[:schema_version])
      assert_equal("request", message.payload[:type])
      refute_nil(message.payload[:dispatched_at])
      assert_equal({name: "consumers.quiet"}, message.payload[:command])
      assert_equal({process_id: process_id}, message.payload[:matchers])
    end
  end

  describe "#stop" do
    before { post "consumers/commanding/#{process_id}/stop" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
      assert_includes(flash[:success], "The Stop command has been dispatched to the")
    end

    it "expect to create new command in the given topic with process_id matcher" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      assert_nil(message.key)
      assert_equal("1.2.0", message.payload[:schema_version])
      assert_equal("request", message.payload[:type])
      refute_nil(message.payload[:dispatched_at])
      assert_equal({name: "consumers.stop"}, message.payload[:command])
      assert_equal({process_id: process_id}, message.payload[:matchers])
    end
  end

  describe "#quiet_all" do
    before { post "consumers/commanding/quiet_all" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
      assert_includes(flash[:success], "The Quiet command has been dispatched to all")
    end

    it "expect to create new command in the given topic with no matchers" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      assert_nil(message.key)
      assert_equal("1.2.0", message.payload[:schema_version])
      assert_equal("request", message.payload[:type])
      refute_nil(message.payload[:dispatched_at])
      assert_equal({name: "consumers.quiet"}, message.payload[:command])
      assert_equal({}, message.payload[:matchers])
    end
  end

  describe "#stop_all" do
    before { post "consumers/commanding/stop_all" }

    it do
      assert_equal(302, response.status)
      # Taken from referer and referer is nil in specs
      assert_equal("/", response.location)
      assert_includes(flash[:success], "The Stop command has been dispatched to all")
    end

    it "expect to create new command in the given topic with no matchers" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      assert_nil(message.key)
      assert_equal("1.2.0", message.payload[:schema_version])
      assert_equal("request", message.payload[:type])
      refute_nil(message.payload[:dispatched_at])
      assert_equal({name: "consumers.stop"}, message.payload[:command])
      assert_equal({}, message.payload[:matchers])
    end
  end
end
