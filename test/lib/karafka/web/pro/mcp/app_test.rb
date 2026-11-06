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

  let(:app) { Karafka::Web::Mcp::App }
  let(:json_headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:result) { JSON.parse(body).fetch("result") }
  let(:rpc_error) { JSON.parse(body).fetch("error") }
  let(:structured) { result.fetch("structuredContent") }

  def rpc(method, params = nil, id: 1, headers: {})
    message = { jsonrpc: "2.0", id: id, method: method }
    message[:params] = params if params
    post "/", message.to_json, json_headers.merge(headers)
  end

  def call_tool(name, arguments = {})
    rpc("tools/call", { name: name, arguments: arguments })
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

  describe "JSON-RPC layer" do
    context "when body is not JSON" do
      before { post "/", "{", json_headers }

      it { assert_equal(-32_700, rpc_error["code"]) }
    end

    context "when body is a batch" do
      before { post "/", "[]", json_headers }

      it { assert_equal(-32_600, rpc_error["code"]) }
    end

    context "when jsonrpc version is missing" do
      before { post "/", { id: 1, method: "ping" }.to_json, json_headers }

      it { assert_equal(-32_600, rpc_error["code"]) }
    end

    context "when request id is null" do
      before { post "/", { jsonrpc: "2.0", id: nil, method: "ping" }.to_json, json_headers }

      it { assert_equal(-32_600, rpc_error["code"]) }
    end

    context "when sending a notification" do
      before do
        post "/", { jsonrpc: "2.0", method: "notifications/initialized" }.to_json, json_headers
      end

      it "accepts it with no body" do
        assert_equal(202, status)
        assert_empty(body)
      end
    end

    context "when sending a response" do
      before { post "/", { jsonrpc: "2.0", id: 1, result: {} }.to_json, json_headers }

      it { assert_equal(202, status) }
    end

    context "when method is unknown" do
      before { rpc("resources/list") }

      it { assert_equal(-32_601, rpc_error["code"]) }
    end

    context "when params are not an object" do
      before { post "/", { jsonrpc: "2.0", id: 7, method: "ping", params: [] }.to_json, json_headers }

      it do
        assert_equal(-32_602, rpc_error["code"])
        assert_equal(7, JSON.parse(body)["id"])
      end
    end

    context "when pinging" do
      before { rpc("ping", id: "abc") }

      it do
        assert_equal({}, result)
        assert_equal("abc", JSON.parse(body)["id"])
        assert_equal("application/json", headers["content-type"])
      end
    end
  end

  describe "initialize" do
    context "when client asks for a supported version" do
      before { rpc("initialize", { protocolVersion: "2025-06-18", capabilities: {} }) }

      it do
        assert_equal("2025-06-18", result["protocolVersion"])
        assert_equal({ "tools" => {} }, result["capabilities"])
        assert_equal("karafka-web", result.dig("serverInfo", "name"))
        assert_equal(Karafka::Web::VERSION, result.dig("serverInfo", "version"))
        assert_includes(result["instructions"], "untrusted")
      end
    end

    context "when client asks for an unknown version" do
      before { rpc("initialize", { protocolVersion: "2030-01-01", capabilities: {} }) }

      it { assert_equal("2025-11-25", result["protocolVersion"]) }
    end

    context "when client asks for a version with JSON-RPC batches" do
      before { rpc("initialize", { protocolVersion: "2025-03-26", capabilities: {} }) }

      it { assert_equal("2025-11-25", result["protocolVersion"]) }
    end
  end

  describe "tools/list" do
    before { rpc("tools/list") }

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
    context "when tool is unknown" do
      before { call_tool("karafka_unknown") }

      it { assert_equal(-32_602, rpc_error["code"]) }
    end

    context "when arguments are unknown" do
      before { call_tool("karafka_overview", { what: 1 }) }

      it { assert_equal(-32_602, rpc_error["code"]) }
    end

    context "when tool fails unexpectedly" do
      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current!).raises(StandardError)
        call_tool("karafka_overview")
      end

      it { assert_equal(-32_603, rpc_error["code"]) }
    end

    describe "karafka_overview" do
      context "when there is state" do
        before { call_tool("karafka_overview") }

        it "returns the dashboard counters" do
          refute(result["isError"])

          counters = structured.fetch("counters")

          %w[messages batches jobs lag_hybrid busy pending errors retries dead processes workers]
            .each { |key| assert_includes(counters.keys, key) }

          assert_equal(structured, JSON.parse(result.dig("content", 0, "text")))
        end
      end

      context "when state is missing" do
        before do
          topics_config.consumers.states.name = create_topic
          call_tool("karafka_overview")
        end

        it "returns a tool error" do
          assert(result["isError"])
          assert_includes(result.dig("content", 0, "text"), "Status page")
        end
      end
    end

    describe "karafka_metrics" do
      context "when range is not provided" do
        before { call_tool("karafka_metrics") }

        it do
          refute(result["isError"])
          assert_equal("seconds", structured["range"])
          refute_empty(structured["aggregated"])
          assert_kind_of(Hash, structured["topics"])
        end
      end

      context "when range is provided" do
        before { call_tool("karafka_metrics", { range: "days" }) }

        it { assert_equal("days", structured["range"]) }
      end

      context "when range is not allowed" do
        before { call_tool("karafka_metrics", { range: "weeks" }) }

        it { assert_equal(-32_602, rpc_error["code"]) }
      end
    end

    describe "errors tools" do
      let(:errors_topic) { create_topic(partitions: 2) }
      let(:error_report) { Fixtures.errors_file }

      before { topics_config.errors.name = errors_topic }

      describe "karafka_errors_list" do
        context "when there are no errors" do
          before { call_tool("karafka_errors_list") }

          it do
            refute(result["isError"])
            assert_empty(structured["errors"])
            assert_nil(structured["next_page"])
          end
        end

        context "when there are errors in many partitions" do
          before do
            produce(errors_topic, error_report, partition: 0)
            produce(errors_topic, error_report, partition: 1)
            produce(errors_topic, "not an error report", partition: 1)
            call_tool("karafka_errors_list")
          end

          it "lists our reports from all partitions" do
            errors = structured["errors"]

            assert_equal([0, 1], errors.map { |error| error["partition"] }.sort)
            assert_equal(%w[error_message], structured["untrusted_fields"])
            assert_nil(structured["next_page"])
          end
        end

        context "when error message is long" do
          let(:error_report) do
            report = JSON.parse(Fixtures.errors_file)
            report["error_message"] = ("a" * 200) + "b"
            report.to_json
          end

          before do
            produce(errors_topic, error_report)
            call_tool("karafka_errors_list")
          end

          it "cuts it as the Web UI does" do
            assert_equal("a" * 200, structured.dig("errors", 0, "error_message"))
          end
        end

        context "when there are more errors than fit on a page" do
          let(:per_page) { Karafka::Web.config.ui.per_page }

          before { produce_many(errors_topic, Array.new(per_page + 1) { error_report }) }

          it "pages through them" do
            call_tool("karafka_errors_list")

            assert_equal(per_page, structured["errors"].size)
            assert_equal(2, structured["next_page"])

            call_tool("karafka_errors_list", { page: 2 })
            second = JSON.parse(body).dig("result", "structuredContent")

            assert_equal(1, second["errors"].size)
            assert_nil(second["next_page"])
          end
        end

        context "when page is invalid" do
          before { call_tool("karafka_errors_list", { page: 0 }) }

          it { assert_equal(-32_602, rpc_error["code"]) }
        end

        context "when errors topic does not exist" do
          let(:errors_topic) { generate_topic_name }

          before { call_tool("karafka_errors_list") }

          it { assert(result["isError"]) }
        end
      end

      describe "karafka_error" do
        context "when report exists" do
          let(:error_report) do
            report = JSON.parse(Fixtures.errors_file)
            report["details"]["sasl.password"] = "secret"
            report["details"]["nested"] = { "ssl.key.password" => "secret" }
            report.to_json
          end

          before do
            produce(errors_topic, error_report, partition: 1)
            call_tool("karafka_error", { partition: 1, offset: 0 })
          end

          it "returns the full report with credentials masked" do
            refute(result["isError"])

            error = structured["error"]

            assert_equal(JSON.parse(error_report)["error_class"], error["error_class"])
            assert_equal("***", error.dig("details", "sasl.password"))
            assert_equal("***", error.dig("details", "nested", "ssl.key.password"))
            refute_includes(result.dig("content", 0, "text"), "secret")
            assert_includes(structured["untrusted_fields"], "backtrace")
          end
        end

        context "when message is not an error report" do
          before do
            produce(errors_topic, "{", partition: 0)
            call_tool("karafka_error", { partition: 0, offset: 0 })
          end

          it do
            assert(result["isError"])
            assert_includes(result.dig("content", 0, "text"), "is not a Karafka error report")
          end
        end

        context "when offset is a transaction marker" do
          before do
            produce(errors_topic, error_report, partition: 0, type: :transactional)
            call_tool("karafka_error", { partition: 0, offset: 1 })
          end

          it do
            assert(result["isError"])
            assert_includes(result.dig("content", 0, "text"), "is a transaction marker")
          end
        end

        context "when partition is empty" do
          before { call_tool("karafka_error", { partition: 0, offset: 0 }) }

          it do
            assert(result["isError"])
            assert_includes(result.dig("content", 0, "text"), "the partition is empty")
          end
        end

        context "when offset is beyond the data" do
          before do
            produce(errors_topic, error_report, partition: 0)
            call_tool("karafka_error", { partition: 0, offset: 100 })
          end

          it do
            assert(result["isError"])
            assert_includes(result.dig("content", 0, "text"), "its offsets are 0 to 0")
          end
        end

        context "when partition does not exist" do
          before { call_tool("karafka_error", { partition: 10, offset: 0 }) }

          it { assert(result["isError"]) }
        end

        context "when arguments are missing" do
          before { call_tool("karafka_error", { partition: 0 }) }

          it { assert_equal(-32_602, rpc_error["code"]) }
        end
      end
    end
  end
end
