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

  context "when mounted through the proxy" do
    let(:app) { Karafka::Web::Mcp::App }

    before { rpc("ping") }

    it { assert_equal({}, result) }
  end
end
