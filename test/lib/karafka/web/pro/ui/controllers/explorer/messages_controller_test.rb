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
  let(:target_topic) { create_topic }

  describe "#forward" do
    context "when we want to republish message from a non-existing topic" do
      before { get "explorer/messages/non-existing/0/1/forward" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:payload) { rand.to_s }

      before do
        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/forward"
      end

      it do
        assert_ok
        assert_body(topic)
        assert_body("message-republish-form")
        refute_body(pagination)
      end
    end
  end

  describe "#republish" do
    context "when we want to republish message from a non-existing topic" do
      before { post "explorer/messages/non-existing/0/1/republish" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:republished) { wait_for_message(target_topic, 0, 0) }
      let(:payload) { rand.to_s }
      let(:target_partition) { 0 }
      let(:include_source_headers) { "on" }
      let(:params) do
        {
          target_topic: target_topic,
          target_partition: target_partition,
          include_source_headers: include_source_headers
        }
      end

      context "when we do not specify the target partition" do
        let(:target_partition) { "" }

        before do
          produce(topic, payload)
          post "explorer/messages/#{topic}/0/0/republish", params
        end

        it do
          assert_equal(302, response.status)
          # Taken from referer and referer is nil in specs
          assert_equal("/", response.location)
          assert_equal(payload, republished.raw_payload)
          assert_includes(republished.headers.keys, "source_topic")
          assert_includes(republished.headers.keys, "source_partition")
          assert_includes(republished.headers.keys, "source_offset")
        end
      end

      context "when we do not want source headers" do
        let(:include_source_headers) { false }

        before do
          produce(topic, payload)
          post "explorer/messages/#{topic}/0/0/republish", params
        end

        it do
          assert_equal(302, response.status)
          assert_equal("/", response.location)
          assert_equal(payload, republished.raw_payload)
          refute_includes(republished.headers.keys, "source_topic")
          refute_includes(republished.headers.keys, "source_partition")
          refute_includes(republished.headers.keys, "source_offset")
        end
      end

      context "when we specify target partition" do
        let(:target_partition) { 1 }
        let(:republished) { wait_for_message(target_topic, 1, 0) }
        let(:target_topic) { create_topic(partitions: 2) }

        before do
          produce(topic, payload)
          post "explorer/messages/#{topic}/0/0/republish", params
        end

        it do
          assert_equal(302, response.status)
          assert_equal("/", response.location)
          assert_equal(payload, republished.raw_payload)
          assert_includes(republished.headers.keys, "source_topic")
          assert_includes(republished.headers.keys, "source_partition")
          assert_includes(republished.headers.keys, "source_offset")
        end
      end
    end

    context "when message exists but republishing is off" do
      let(:payload) { rand.to_s }

      before do
        Karafka::Web.config.ui.policies.messages.stubs(:republish?).returns(false)

        produce(topic, payload)
        post "explorer/messages/#{topic}/0/0/republish"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end
  end

  describe "#publish" do
    context "when the topic does not exist" do
      before { get "explorer/messages/non-existing/publish" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when the topic exists" do
      before { get "explorer/messages/#{topic}/publish" }

      it do
        assert_ok
        assert_body(topic)
        assert_body("message-publish-form")
        refute_body(pagination)
      end
    end

    context "when publishing is off" do
      before do
        Karafka::Web.config.ui.policies.messages.stubs(:publish?).returns(false)

        get "explorer/messages/#{topic}/publish"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end

    context "when a partition is provided (e.g. from a per-partition view)" do
      let(:topic) { create_topic(partitions: 2) }

      before { get "explorer/messages/#{topic}/publish?partition=1" }

      it "preselects that partition in the form" do
        assert_ok
        assert_match(/value="1"\s+selected/, response.body)
      end
    end
  end

  describe "#dispatch" do
    let(:payload) { rand.to_s }
    let(:published) { wait_for_message(topic, 0, 0) }

    context "when the topic does not exist" do
      before { post "explorer/messages/non-existing/publish", payload: payload }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when publishing is off" do
      before do
        Karafka::Web.config.ui.policies.messages.stubs(:publish?).returns(false)

        post "explorer/messages/#{topic}/publish", payload: payload
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end

    context "when we publish with only a payload" do
      before { post "explorer/messages/#{topic}/publish", payload: payload, payload_format: "raw" }

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}", response.location)
        assert_equal(payload, published.raw_payload)
        assert_nil(published.raw_key)
      end
    end

    context "when we publish with a key" do
      let(:key) { "my-key" }

      before do
        post "explorer/messages/#{topic}/publish", payload: payload, key: key, payload_format: "raw"
      end

      it do
        assert_equal(302, response.status)
        assert_equal(payload, published.raw_payload)
        assert_equal(key, published.key)
      end
    end

    context "when we publish with an explicit partition" do
      let(:topic) { create_topic(partitions: 2) }
      let(:published) { wait_for_message(topic, 1, 0) }

      before do
        post(
          "explorer/messages/#{topic}/publish",
          payload: payload,
          partition: 1,
          payload_format: "raw"
        )
      end

      it do
        assert_equal(302, response.status)
        assert_equal(payload, published.raw_payload)
        assert_equal(1, published.partition)
      end
    end

    context "when we publish with headers" do
      before do
        post(
          "explorer/messages/#{topic}/publish",
          payload: payload,
          payload_format: "raw",
          # includes a blank line which must be tolerated
          headers: "source: web-ui\nkind: manual\n\n"
        )
      end

      it do
        assert_equal(302, response.status)
        assert_equal(payload, published.raw_payload)
        assert_equal("web-ui", published.headers["source"])
        assert_equal("manual", published.headers["kind"])
      end
    end

    context "when a header line is malformed (no colon)" do
      before do
        post(
          "explorer/messages/#{topic}/publish",
          payload: "hello",
          payload_format: "raw",
          headers: "source: web-ui\nno-colon-line"
        )
      end

      it "re-renders the form with an error instead of producing" do
        assert_ok
        assert_body("message-publish-form")
        assert_body("Each header must be on its own line")
      end
    end

    context "when we publish with the raw format explicitly" do
      let(:payload) { "  not json at all  " }

      before do
        post "explorer/messages/#{topic}/publish", payload: payload, payload_format: "raw"
      end

      it "produces the payload exactly as provided" do
        assert_equal(302, response.status)
        assert_equal(payload, published.raw_payload)
      end
    end

    context "when we publish an uploaded file as the payload" do
      let(:file_content) { "binary\x00payload-#{rand}".b }
      let(:upload) do
        tempfile = Tempfile.new(%w[payload .bin])
        tempfile.binmode
        tempfile.write(file_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, "application/octet-stream", true)
      end

      before do
        post "explorer/messages/#{topic}/publish", payload_format: "raw", payload_file: upload
      end

      it "produces the uploaded file bytes as the payload" do
        assert_equal(302, response.status)
        assert_equal(file_content, published.raw_payload)
      end
    end

    context "when both a payload text and an uploaded file are provided" do
      let(:file_content) { "from-file-#{rand}" }
      let(:upload) do
        tempfile = Tempfile.new(%w[payload .bin])
        tempfile.binmode
        tempfile.write(file_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, "application/octet-stream", true)
      end

      before do
        post(
          "explorer/messages/#{topic}/publish",
          payload_format: "raw",
          payload: "from-text",
          payload_file: upload
        )
      end

      it "prefers the uploaded file over the text" do
        assert_equal(302, response.status)
        assert_equal(file_content, published.raw_payload)
      end
    end

    context "when we publish with the JSON format and valid JSON" do
      before do
        post(
          "explorer/messages/#{topic}/publish",
          payload: '{ "a" : 1, "b" : [2, 3] }',
          payload_format: "json"
        )
      end

      it "produces the canonical serialization of the parsed JSON" do
        assert_equal(302, response.status)
        assert_equal('{"a":1,"b":[2,3]}', published.raw_payload)
      end
    end

    context "when we publish with the JSON format but invalid JSON" do
      before do
        post(
          "explorer/messages/#{topic}/publish",
          payload: "{ not valid json",
          payload_format: "json"
        )
      end

      it "re-renders the form with an error instead of producing" do
        assert_ok
        assert_body("message-publish-form")
        assert_body("not valid JSON")
      end

      it "renders the error exactly once" do
        assert_equal(1, response.body.scan("could not be serialized").count)
      end
    end
  end

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
