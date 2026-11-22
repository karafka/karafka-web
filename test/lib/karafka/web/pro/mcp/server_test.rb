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
  let(:server) { described_class.new }
  let(:response) { server.call(request.is_a?(String) ? request : request.to_json) }
  let(:status) { response[0] }
  let(:payload) { JSON.parse(response[2].join) }
  let(:result) { payload.fetch("result") }
  let(:rpc_error) { payload.fetch("error") }
  let(:params) { nil }
  let(:request) do
    message = { jsonrpc: "2.0", id: 1, method: rpc_method }
    message[:params] = params if params
    message
  end

  def code(type)
    described_class::ERRORS.fetch(type)
  end

  context "when body is not JSON" do
    let(:request) { "{" }

    it { assert_equal(code(:parse), rpc_error["code"]) }
  end

  context "when body is a batch" do
    let(:request) { [{ jsonrpc: "2.0", id: 1, method: "ping" }] }

    it { assert_equal(code(:invalid_request), rpc_error["code"]) }
  end

  context "when jsonrpc version is missing" do
    let(:request) { { id: 1, method: "ping" } }

    it { assert_equal(code(:invalid_request), rpc_error["code"]) }
  end

  context "when request id is null" do
    let(:request) { { jsonrpc: "2.0", id: nil, method: "ping" } }

    it { assert_equal(code(:invalid_request), rpc_error["code"]) }
  end

  context "when method is not a string" do
    let(:request) { { jsonrpc: "2.0", id: 1, method: 1 } }

    it { assert_equal(code(:invalid_request), rpc_error["code"]) }
  end

  context "when sending a notification" do
    let(:request) { { jsonrpc: "2.0", method: "notifications/initialized" } }

    it "accepts it with no body" do
      assert_equal(202, status)
      assert_empty(response[2])
    end
  end

  context "when sending a response" do
    let(:request) { { jsonrpc: "2.0", id: 1, result: {} } }

    it { assert_equal(202, status) }
  end

  context "when method is unknown" do
    let(:rpc_method) { "resources/list" }

    it { assert_equal(code(:method_not_found), rpc_error["code"]) }
  end

  context "when params are not an object" do
    let(:request) { { jsonrpc: "2.0", id: 7, method: "ping", params: [] } }

    it do
      assert_equal(code(:invalid_params), rpc_error["code"])
      assert_equal(7, payload["id"])
    end
  end

  context "when pinging" do
    let(:request) { { jsonrpc: "2.0", id: "abc", method: "ping" } }

    it do
      assert_equal({}, result)
      assert_equal("abc", payload["id"])
    end
  end

  describe "initialize" do
    let(:rpc_method) { "initialize" }
    let(:params) { { protocolVersion: version, capabilities: {} } }

    context "when client asks for a supported version" do
      let(:version) { "2025-06-18" }

      it do
        assert_equal("2025-06-18", result["protocolVersion"])
        assert_equal({ "tools" => {} }, result["capabilities"])
        assert_equal("karafka-web", result.dig("serverInfo", "name"))
        assert_equal(Karafka::Web::VERSION, result.dig("serverInfo", "version"))
        assert_includes(result["instructions"], "untrusted")
      end
    end

    context "when client asks for an unknown version" do
      let(:version) { "2030-01-01" }

      it { assert_equal("2025-11-25", result["protocolVersion"]) }
    end

    context "when client asks for a version with JSON-RPC batches" do
      let(:version) { "2025-03-26" }

      it { assert_equal("2025-11-25", result["protocolVersion"]) }
    end
  end

  describe "tools/list" do
    let(:rpc_method) { "tools/list" }
    let(:tools) { result.fetch("tools") }

    it "lists the read-only tools" do
      assert_equal(
        %w[
          karafka_overview karafka_metrics karafka_health karafka_cluster_lags karafka_processes
          karafka_consumer_groups karafka_errors_list karafka_error
        ],
        tools.map { |tool| tool["name"] }
      )

      tools.each do |tool|
        assert_equal("object", tool.dig("inputSchema", "type"))
        assert(tool.dig("annotations", "readOnlyHint"))
      end
    end

    it "requires error coordinates for the error details" do
      error_tool = tools.find { |tool| tool["name"] == "karafka_error" }

      assert_equal(%w[partition offset], error_tool.dig("inputSchema", "required"))
    end
  end

  describe "tools/call" do
    let(:rpc_method) { "tools/call" }
    let(:params) { { name: tool_name, arguments: arguments } }
    let(:tool_name) { "karafka_overview" }
    let(:arguments) { {} }

    context "when tool is unknown" do
      let(:tool_name) { "karafka_unknown" }

      it { assert_equal(code(:invalid_params), rpc_error["code"]) }
    end

    context "when arguments are not an object" do
      let(:arguments) { [] }

      it { assert_equal(code(:invalid_params), rpc_error["code"]) }
    end

    context "when arguments do not pass the tool contract" do
      let(:arguments) { { what: 1 } }

      it do
        assert_equal(code(:invalid_params), rpc_error["code"])
        assert_equal("arguments contain an unknown argument", rpc_error["message"])
      end
    end

    context "when tool fails unexpectedly" do
      before { Karafka::Web::Ui::Models::ConsumersState.stubs(:current!).raises(StandardError) }

      it { assert_equal(code(:internal), rpc_error["code"]) }
    end

    context "when tool works" do
      it "returns its result" do
        refute(result["isError"])
        assert(result.dig("structuredContent", "counters").key?("messages"))
      end
    end
  end

  describe "audit log" do
    let(:server) { described_class.new(Karafka::Web::Pro::Mcp::Audit.new(env)) }
    let(:env) { { "REMOTE_ADDR" => "10.0.0.2", "HTTP_USER_AGENT" => "agent/2.0" } }
    let(:audit_topic) { create_topic }
    let(:rpc_method) { "tools/call" }
    let(:params) { { name: tool_name, arguments: arguments } }
    let(:tool_name) { "karafka_overview" }
    let(:arguments) { {} }
    let(:records) do
      Karafka.producer.client.flush

      Karafka::Admin
        .read_topic(audit_topic, 0, 100)
        .map { |message| JSON.parse(message.raw_payload) }
    end
    let(:failing) { stub }
    let(:executions) { [] }
    let(:changing_tool) do
      calls = executions

      contract = Class.new(Karafka::Web::Pro::Mcp::Tools::Contracts::Base) do
        arguments(:topic)

        required(:topic) { |val| val.is_a?(String) }
      end

      Class.new(Karafka::Web::Pro::Mcp::Tools::Base) do
        tool(
          "karafka_test_change",
          "Test changing tool",
          contract: contract.new,
          operation: :delete_records
        )

        define_method(:topics) { [@arguments[:topic]] }

        define_method(:fetch) do
          calls << @arguments[:topic]
          { topic: @arguments[:topic], deleted: 3 }
        end
      end
    end

    before do
      Karafka::Web.config.topics.mcp_audit.name = audit_topic
      failing.stubs(:produce_sync).raises(WaterDrop::Errors::ProduceError)
      failing.stubs(:produce_async).raises(WaterDrop::Errors::ProduceError)
    end

    after { Karafka::Web.config.mcp.audit.fail_closed_reads = false }

    context "when read-only tool works" do
      it "writes one result record" do
        refute(result["isError"])
        assert_equal(1, records.size)
        assert_equal("result", records.first["type"])
        assert_equal("karafka_overview", records.first["tool"])
        assert_equal("ok", records.first["outcome"])
        assert_equal("10.0.0.2", records.first.dig("actor", "remote_ip"))
        assert_kind_of(Float, records.first["duration"])
      end
    end

    context "when read-only tool returns a tool error" do
      let(:tool_name) { "karafka_error" }
      let(:arguments) { { partition: 0, offset: 1_000_000 } }

      it "writes the tool error with its message" do
        assert(result["isError"])
        assert_equal(1, records.size)
        assert_equal("tool_error", records.first["outcome"])
        assert_equal(result.dig("content", 0, "text"), records.first["error"])
      end
    end

    context "when read-only tool fails unexpectedly" do
      before { Karafka::Web::Ui::Models::ConsumersState.stubs(:current!).raises(StandardError) }

      it "writes the exception class" do
        assert_equal(code(:internal), rpc_error["code"])
        assert_equal(1, records.size)
        assert_equal("exception", records.first["outcome"])
        assert_equal("StandardError", records.first["error"])
      end
    end

    context "when tool is unknown" do
      let(:tool_name) { "karafka_unknown" }

      it "writes the rejection" do
        assert_equal(code(:invalid_params), rpc_error["code"])
        assert_equal(1, records.size)
        assert_equal("rejected", records.first["outcome"])
        assert_equal("karafka_unknown", records.first["tool"])
        assert_equal("Unknown tool: karafka_unknown", records.first["error"])
      end
    end

    context "when arguments do not pass the tool contract" do
      let(:arguments) { { what: 1 } }

      it "writes the rejection with the arguments" do
        assert_equal(code(:invalid_params), rpc_error["code"])
        assert_equal("rejected", records.first["outcome"])
        assert_equal({ "what" => 1 }, records.first["arguments"])
      end
    end

    context "when tools/call params are not an object" do
      let(:params) { nil }
      let(:request) { { jsonrpc: "2.0", id: 1, method: "tools/call", params: [] } }

      it "writes the rejection" do
        assert_equal(code(:invalid_params), rpc_error["code"])
        assert_equal("rejected", records.first["outcome"])
      end
    end

    context "when the requests policy denied the call" do
      before { server.denied(request.to_json) }

      it "writes the rejection" do
        assert_equal(1, records.size)
        assert_equal("rejected", records.first["outcome"])
        assert_equal("Forbidden", records.first["error"])
        assert_equal("karafka_overview", records.first["tool"])
      end
    end

    context "when read-only audit write fails" do
      before { Karafka::Web.producers.stubs(:default).returns(failing) }

      it "still answers" do
        refute(result["isError"])
        assert(result.dig("structuredContent", "counters").key?("messages"))
      end

      context "when reads fail closed" do
        before do
          Karafka::Web.config.mcp.audit.fail_closed_reads = true
          Karafka::Web.producers.stubs(:fully_acked).returns(failing)
        end

        it "refuses the result" do
          assert_equal(code(:internal), rpc_error["code"])
          assert_equal("Audit log is not available", rpc_error["message"])
        end
      end
    end

    context "when changing tool is called" do
      let(:tool_name) { "karafka_test_change" }
      let(:arguments) { { topic: "orders" } }

      before do
        described_class
          .any_instance
          .stubs(:tools)
          .returns({ "karafka_test_change" => changing_tool })
      end

      it "writes the intent before acting and the outcome after" do
        refute(result["isError"])
        assert_equal(%w[orders], executions)
        assert_equal(%w[intent result], records.map { |record| record["type"] })
        assert_equal(1, records.map { |record| record["call_id"] }.uniq.size)
        assert_equal("ok", records.last["outcome"])
        assert_equal({ "topic" => "orders", "deleted" => 3 }, records.last["summary"])
      end

      it "is not marked read-only" do
        refute(changing_tool.definition.dig(:annotations, :readOnlyHint))
      end

      context "when the intent cannot be written" do
        before { Karafka::Web.producers.stubs(:fully_acked).returns(failing) }

        it "refuses the call without acting" do
          assert_equal(code(:internal), rpc_error["code"])
          assert_equal("Audit log is not available, the call was refused", rpc_error["message"])
          assert_empty(executions)
          assert_empty(records)
        end
      end

      context "when it targets the audit topic" do
        let(:arguments) { { topic: audit_topic } }

        it "refuses the call without acting and writes the rejection" do
          assert_equal(code(:invalid_params), rpc_error["code"])
          assert_equal("The MCP audit topic cannot be changed through MCP", rpc_error["message"])
          assert_empty(executions)
          assert_equal(%w[rejected], records.map { |record| record["outcome"] })
        end
      end
    end
  end
end
