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

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:commands_topic) { create_topic }
  let(:process_id) { SecureRandom.uuid }

  before { topics_config.consumers.commands.name = commands_topic }

  describe "#trace" do
    before { post "consumers/commanding/#{process_id}/trace" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq("/")
      expect(flash[:success]).to include("The Trace command has been dispatched to the")
    end

    it "expect to create new command in the given topic with process_id matcher" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to be_nil
      expect(message.payload[:schema_version]).to eq("1.2.0")
      expect(message.payload[:type]).to eq("request")
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: "consumers.trace")
      expect(message.payload[:matchers]).to eq(process_id: process_id)
    end
  end

  describe "#quiet" do
    before { post "consumers/commanding/#{process_id}/quiet" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq("/")
      expect(flash[:success]).to include("The Quiet command has been dispatched to the")
    end

    it "expect to create new command in the given topic with process_id matcher" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to be_nil
      expect(message.payload[:schema_version]).to eq("1.2.0")
      expect(message.payload[:type]).to eq("request")
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: "consumers.quiet")
      expect(message.payload[:matchers]).to eq(process_id: process_id)
    end
  end

  describe "#stop" do
    before { post "consumers/commanding/#{process_id}/stop" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq("/")
      expect(flash[:success]).to include("The Stop command has been dispatched to the")
    end

    it "expect to create new command in the given topic with process_id matcher" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to be_nil
      expect(message.payload[:schema_version]).to eq("1.2.0")
      expect(message.payload[:type]).to eq("request")
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: "consumers.stop")
      expect(message.payload[:matchers]).to eq(process_id: process_id)
    end
  end

  describe "#quiet_all" do
    before { post "consumers/commanding/quiet_all" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq("/")
      expect(flash[:success]).to include("The Quiet command has been dispatched to all")
    end

    it "expect to create new command in the given topic with no matchers" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to be_nil
      expect(message.payload[:schema_version]).to eq("1.2.0")
      expect(message.payload[:type]).to eq("request")
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: "consumers.quiet")
      expect(message.payload[:matchers]).to eq({})
    end
  end

  describe "#stop_all" do
    before { post "consumers/commanding/stop_all" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq("/")
      expect(flash[:success]).to include("The Stop command has been dispatched to all")
    end

    it "expect to create new command in the given topic with no matchers" do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to be_nil
      expect(message.payload[:schema_version]).to eq("1.2.0")
      expect(message.payload[:type]).to eq("request")
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: "consumers.stop")
      expect(message.payload[:matchers]).to eq({})
    end
  end
end
