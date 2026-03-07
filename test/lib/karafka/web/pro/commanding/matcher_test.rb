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
  let(:matcher) { described_class.new }

  let(:process_id) { "1234" }
  let(:schema_version) { "1.2.0" }
  let(:message) do
    stub(key: message_key,
      payload: message_payload,
      headers: { "type" => message_payload[:type] })
  end

  before do
    Karafka::Web.config.tracking.consumers.sampler.stubs(:process_id).returns(process_id)

    stub_const("Karafka::Web::Pro::Commanding::Dispatcher::SCHEMA_VERSION", schema_version)
  end

  context "when message is a command of current schema version without process_id filter" do
    let(:message_key) { nil }
    let(:message_payload) { { type: "request", schema_version: schema_version } }

    it { assert(matcher.matches?(message)) }
  end

  context "when process_id in matchers matches current process" do
    let(:message_key) { nil }
    let(:message_payload) do
      { type: "request", schema_version: schema_version, matchers: { process_id: process_id } }
    end

    it { assert(matcher.matches?(message)) }
  end

  context "when process_id in matchers does not match current process" do
    let(:message_key) { nil }
    let(:message_payload) do
      {
        type: "request",
        schema_version: schema_version,
        matchers: { process_id: "other_process_id" }
      }
    end

    it { refute(matcher.matches?(message)) }
  end

  context "when message type is not command" do
    let(:message_key) { nil }
    let(:message_payload) { { type: "result", schema_version: schema_version } }

    it { refute(matcher.matches?(message)) }
  end

  context "when message schema version does not match" do
    let(:message_key) { nil }
    let(:message_payload) { { type: "request", schema_version: "2.0" } }

    it { refute(matcher.matches?(message)) }
  end

  describe "matchers filtering" do
    let(:message_key) { nil }

    let(:consumer_group) do
      stub(id: "my_consumer_group")
    end

    let(:topic) do
      stub(name: "my_topic", consumer_group: consumer_group)
    end

    let(:assignments) { { topic => [0, 1, 2] } }

    before do
      Karafka::App.stubs(:assignments).returns(assignments)
    end

    context "when no matchers are specified" do
      let(:message_payload) do
        { type: "request", schema_version: schema_version }
      end

      it { assert(matcher.matches?(message)) }
    end

    context "when matchers is empty hash" do
      let(:message_payload) do
        { type: "request", schema_version: schema_version, matchers: {} }
      end

      it { assert(matcher.matches?(message)) }
    end

    context "with consumer_group_id matcher" do
      context "when consumer_group_id matches an assignment" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: { consumer_group_id: "my_consumer_group" }
          }
        end

        it { assert(matcher.matches?(message)) }
      end

      context "when consumer_group_id does not match any assignment" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: { consumer_group_id: "other_consumer_group" }
          }
        end

        it { refute(matcher.matches?(message)) }
      end
    end

    context "with topic matcher" do
      context "when topic matches an assignment" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: { topic: "my_topic" }
          }
        end

        it { assert(matcher.matches?(message)) }
      end

      context "when topic does not match any assignment" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: { topic: "other_topic" }
          }
        end

        it { refute(matcher.matches?(message)) }
      end
    end

    context "with multiple matchers (AND logic)" do
      context "when all matchers match" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: {
              consumer_group_id: "my_consumer_group",
              topic: "my_topic"
            }
          }
        end

        it { assert(matcher.matches?(message)) }
      end

      context "when one matcher fails" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: {
              consumer_group_id: "my_consumer_group",
              topic: "other_topic"
            }
          }
        end

        it { refute(matcher.matches?(message)) }
      end

      context "when all matchers fail" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: {
              consumer_group_id: "other_consumer_group",
              topic: "other_topic"
            }
          }
        end

        it { refute(matcher.matches?(message)) }
      end
    end

    context "with unknown matcher type" do
      let(:message_payload) do
        {
          type: "request",
          schema_version: schema_version,
          matchers: { unknown_matcher: "some_value" }
        }
      end

      it "ignores unknown matchers for forward compatibility" do
        assert(matcher.matches?(message))
      end
    end

    context "with unknown matcher combined with known matcher" do
      context "when known matcher passes" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: {
              consumer_group_id: "my_consumer_group",
              unknown_matcher: "some_value"
            }
          }
        end

        it { assert(matcher.matches?(message)) }
      end

      context "when known matcher fails" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: {
              consumer_group_id: "other_consumer_group",
              unknown_matcher: "some_value"
            }
          }
        end

        it { refute(matcher.matches?(message)) }
      end
    end

    context "when no assignments exist" do
      let(:assignments) { {} }

      context "with consumer_group_id matcher" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: { consumer_group_id: "my_consumer_group" }
          }
        end

        it { refute(matcher.matches?(message)) }
      end

      context "with topic matcher" do
        let(:message_payload) do
          {
            type: "request",
            schema_version: schema_version,
            matchers: { topic: "my_topic" }
          }
        end

        it { refute(matcher.matches?(message)) }
      end
    end
  end
end
