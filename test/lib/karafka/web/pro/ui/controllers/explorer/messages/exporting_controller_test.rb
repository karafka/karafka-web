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

  let(:topic) { create_topic }

  describe "#download" do
    context "when we want to download message from a non-existing topic" do
      before { get "explorer/messages/non-existing/0/1/download" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.msg" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/download"
      end

      it do
        assert_ok
        assert_equal(expected_disposition, response.headers["content-disposition"])
        assert_equal("application/octet-stream", response.headers["content-type"])
        assert_equal(payload, response.body)
      end
    end

    context "when message exists but downloads are off" do
      let(:payload) { rand.to_s }

      before do
        Karafka::Web.config.ui.policies.messages.stubs(:download?).returns(false)

        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/download"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end
  end

  describe "#export" do
    context "when we want to export message from a non-existing topic" do
      before { get "explorer/messages/non-existing/0/1/export" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      # Export deserializes the payload (default JSON deserializer) and re-serializes it with
      # `#to_json`. A bare numeric payload like `rand.to_s` is not a JSON serialization fixed
      # point: Ruby's `Float#to_s` and the json gem's float encoder occasionally disagree (e.g.
      # scientific notation or precision), so `assert_equal(payload, response.body)` was flaky
      # for roughly 1-in-2000 random values. A JSON string literal round-trips identically.
      let(:payload) { rand.to_s.to_json }
      let(:expected_file_name) { "#{topic}_0_0_payload.json" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/export"
      end

      it do
        assert_ok
        assert_equal(expected_disposition, response.headers["content-disposition"])
        assert_equal("application/octet-stream", response.headers["content-type"])
        assert_equal(payload, response.body)
      end
    end

    context "when message exists on a dynamic topic with custom deserializer" do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.json" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        topic_name = topic

        draw_routes do
          pattern(/#{topic_name}/) do
            active(false)
            deserializer(->(_message) { "1" })
          end
        end

        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/export"
      end

      it "expect to use custom deserializer" do
        assert_ok
        assert_equal(expected_disposition, response.headers["content-disposition"])
        assert_equal("application/octet-stream", response.headers["content-type"])
        assert_equal('"1"', response.body)
      end
    end

    context "when message exists but exports are off" do
      let(:payload) { rand.to_s }

      before do
        Karafka::Web.config.ui.policies.messages.stubs(:export?).returns(false)

        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/export"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end

    context "when message payload is JSON with non-UTF-8 encoded string values" do
      before do
        # JSON.parse accepts this payload but the resulting hash contains strings with invalid
        # UTF-8 bytes, so serializing it back with #to_json raises JSON::GeneratorError. There
        # is no JSON representation that could be exported, hence 404
        produce(topic, Fixtures.binfile("payloads/invalid_utf8.bin"))
        get "explorer/messages/#{topic}/0/0/export"
      end

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end
  end
end
