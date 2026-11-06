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
        %w[karafka_overview karafka_metrics karafka_errors_list karafka_error],
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
end
