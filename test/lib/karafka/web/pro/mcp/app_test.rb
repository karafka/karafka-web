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
  include Rack::Test::Methods
  include ControllerHelper

  let(:app) { described_class }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:result) { JSON.parse(body).fetch("result") }

  def rpc(method, params = nil, id: 1, headers: {})
    message = { jsonrpc: "2.0", id: id, method: method }
    message[:params] = params if params
    post "/", message.to_json, json_headers.merge(headers)
  end

  describe "HTTP layer" do
    context "when using GET" do
      before { get "/" }

      it "refuses it as we offer no SSE stream" do
        assert_equal(405, status)
        assert_equal("POST", headers["allow"])
      end
    end

    context "when posting to a sub-path" do
      before { post "/other", "{}", json_headers }

      it { assert_equal(404, status) }
    end

    context "when content type is not JSON" do
      before { post "/", "{}", { "CONTENT_TYPE" => "text/plain" } }

      it { assert_equal(415, status) }
    end

    context "when origin is foreign" do
      before { rpc("ping", headers: { "HTTP_ORIGIN" => "https://evil.example" }) }

      it { assert_equal(403, status) }
    end

    context "when origin is ours" do
      before { rpc("ping", headers: { "HTTP_ORIGIN" => "http://example.org" }) }

      it { assert_equal(200, status) }
    end

    context "when protocol version header is not supported" do
      before { rpc("ping", headers: { "HTTP_MCP_PROTOCOL_VERSION" => "1999-01-01" }) }

      it { assert_equal(400, status) }
    end

    context "when protocol version header is one we do not support" do
      before { rpc("ping", headers: { "HTTP_MCP_PROTOCOL_VERSION" => "2025-03-26" }) }

      it { assert_equal(400, status) }
    end

    context "when protocol version header is supported" do
      before { rpc("ping", headers: { "HTTP_MCP_PROTOCOL_VERSION" => "2025-11-25" }) }

      it { assert_equal(200, status) }
    end

    context "when requests policy denies the request" do
      before do
        Karafka::Web.config.ui.policies.requests.stubs(:allow?).returns(false)
        rpc("ping")
      end

      it { assert_equal(403, status) }
    end

    it "does not set any session cookie" do
      rpc("ping")

      assert_nil(headers["set-cookie"])
    end
  end

  describe "JSON-RPC" do
    before { rpc("tools/call", { name: "karafka_overview", arguments: {} }) }

    it "answers the request with its result" do
      assert_equal(200, status)
      assert_equal("application/json", headers["content-type"])
      refute(result["isError"])
      assert(result.dig("structuredContent", "counters").key?("messages"))
    end
  end

  describe "messages tools" do
    let(:topic_name) { create_topic }
    let(:tool_names) { result.fetch("tools").map { |tool| tool["name"] } }
    let(:arguments) { { topic_name: topic_name, partition: 0, offset: 0 } }

    before { produce(topic_name, { "user" => "jane" }.to_json, key: "k1") }

    context "when they are disabled" do
      it "does not list them and refuses a call" do
        rpc("tools/list")

        refute_includes(tool_names, "karafka_message")

        rpc("tools/call", { name: "karafka_message", arguments: arguments })

        assert_includes(JSON.parse(body).dig("error", "message"), "is disabled")
        refute_includes(body, "jane")
      end
    end

    context "when they are enabled" do
      before { Karafka::Web.config.mcp.messages.active = true }

      after { Karafka::Web.config.mcp.messages.active = false }

      it "lists them and returns the message" do
        rpc("tools/list")

        assert_includes(tool_names, "karafka_message")

        rpc("tools/call", { name: "karafka_message", arguments: arguments })

        message = JSON.parse(body).dig("result", "structuredContent")

        assert_equal(200, status)
        assert_equal({ "user" => "jane" }, message["payload"])
        assert_equal("k1", message["key"])
      end
    end
  end

  describe "audit log" do
    let(:audit_topic) { create_topic }
    let(:records) do
      Karafka.producer.client.flush

      Karafka::Admin
        .read_topic(audit_topic, 0, 100)
        .map { |message| JSON.parse(message.raw_payload) }
    end
    let(:call) { { name: "karafka_overview", arguments: {} } }
    let(:agent) { { "HTTP_USER_AGENT" => "claude-code/2.0", "REMOTE_ADDR" => "10.1.1.1" } }

    before { Karafka::Web.config.topics.mcp_audit.name = audit_topic }

    after { Karafka::Web.config.mcp.audit.actor = nil }

    context "when tool is called over HTTP" do
      before { rpc("tools/call", call, headers: agent) }

      it "records the call with the request actor" do
        assert_equal(1, records.size)
        assert_equal("ok", records.first["outcome"])
        assert_equal(
          { "remote_ip" => "10.1.1.1", "user_agent" => "claude-code/2.0" },
          records.first["actor"]
        )
      end
    end

    context "when actor callable reads the host app auth from the Rack env" do
      before do
        Karafka::Web.config.mcp.audit.actor = ->(env) { env.fetch("app.user", nil) }
        rpc("tools/call", call, headers: agent.merge("app.user" => "ops@example.com"))
      end

      it { assert_equal("ops@example.com", records.first["actor"]) }
    end

    context "when requests policy denies the call" do
      before do
        Karafka::Web.config.ui.policies.requests.stubs(:allow?).returns(false)
        rpc("tools/call", call, headers: agent)
      end

      it "records the rejection" do
        assert_equal(403, status)
        assert_equal(%w[rejected], records.map { |record| record["outcome"] })
        assert_equal("Forbidden", records.first["error"])
      end
    end

    context "when topics and routing tools are called" do
      let(:topic_id) { Karafka::App.routes.first.topics.first.id }
      let(:calls) do
        [
          { name: "karafka_topics", arguments: {} },
          { name: "karafka_topic_configs", arguments: { topic_name: audit_topic } },
          { name: "karafka_routing", arguments: {} },
          { name: "karafka_routing_topic", arguments: { topic_id: topic_id } }
        ]
      end

      before { calls.each { |tool_call| rpc("tools/call", tool_call, headers: agent) } }

      it "answers and records each call" do
        assert_equal(%w[ok ok ok ok], records.map { |record| record["outcome"] })
        assert_equal(calls.map { |tool_call| tool_call[:name] }, records.map { |record| record["tool"] })
      end
    end

    context "when requests policy denies topics and routing tools" do
      let(:calls) do
        [
          { name: "karafka_topics", arguments: {} },
          { name: "karafka_topic_configs", arguments: { topic_name: audit_topic } },
          { name: "karafka_routing", arguments: {} },
          { name: "karafka_routing_topic", arguments: { topic_id: "test" } }
        ]
      end
      let(:statuses) { [] }

      before do
        Karafka::Web.config.ui.policies.requests.stubs(:allow?).returns(false)

        calls.each do |tool_call|
          rpc("tools/call", tool_call, headers: agent)
          statuses << status
        end
      end

      it "refuses and records each call" do
        assert_equal([403] * 4, statuses)
        assert_equal(%w[rejected] * 4, records.map { |record| record["outcome"] })
        assert_equal(calls.map { |tool_call| tool_call[:name] }, records.map { |record| record["tool"] })
      end
    end

    context "when topics and routing tools get arguments their contracts reject" do
      before do
        rpc("tools/call", { name: "karafka_topic_configs", arguments: { topic_name: "a b" } })
        rpc("tools/call", { name: "karafka_routing_topic", arguments: { topic_id: 1 } })
      end

      it "records the rejections with the contract errors" do
        assert_equal(%w[rejected rejected], records.map { |record| record["outcome"] })
        assert_equal("topic_name needs to be a valid Kafka topic name", records.first["error"])
        assert_equal("topic_id needs to be a non-empty string", records.last["error"])
      end
    end

    context "when requests policy denies the call and actor callable raises" do
      before do
        Karafka::Web.config.ui.policies.requests.stubs(:allow?).returns(false)
        Karafka::Web.config.mcp.audit.actor = ->(_env) { raise ArgumentError }
        rpc("tools/call", call, headers: agent)
      end

      it "still refuses with 403 and records the rejection" do
        assert_equal(403, status)
        assert_equal(%w[rejected], records.map { |record| record["outcome"] })
      end
    end

    context "when the audit cannot be built for a denied call" do
      before do
        Karafka::Web.config.ui.policies.requests.stubs(:allow?).returns(false)
        Karafka::Web::Pro::Mcp::Audit.any_instance.stubs(:result).raises(StandardError)
        rpc("tools/call", call, headers: agent)
      end

      it { assert_equal(403, status) }
    end

    context "when not calling a tool" do
      before { rpc("ping") }

      it { assert_empty(records) }
    end
  end

  context "when mounted through the proxy" do
    let(:app) { Karafka::Web::Mcp::App }

    before { rpc("ping") }

    it { assert_equal({}, result) }
  end
end
