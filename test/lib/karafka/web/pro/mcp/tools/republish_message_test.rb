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
  let(:server) { Karafka::Web::Pro::Mcp::Server.new(Karafka::Web::Pro::Mcp::Audit.new({})) }
  let(:audit_topic) { create_topic }
  let(:payload) { rpc("tools/call", { name: described_class.name, arguments: arguments }) }
  let(:result) { payload.fetch("result") }
  let(:rpc_error) { payload.fetch("error") }
  let(:listed) { rpc("tools/list").dig("result", "tools").map { |tool| tool["name"] } }
  let(:failing) { stub }
  let(:records) do
    Karafka.producer.client.flush

    Karafka::Admin
      .read_topic(audit_topic, 0, 100)
      .map { |message| JSON.parse(message.raw_payload) }
  end

  def rpc(rpc_method, params = nil)
    request = { jsonrpc: "2.0", id: 1, method: rpc_method }
    request[:params] = params if params

    JSON.parse(server.call(request.to_json)[2].join)
  end

  before do
    Karafka::Web.config.topics.mcp_audit.name = audit_topic
    Karafka::Web.config.mcp.changing_tools = [described_class.name]
    failing.stubs(:produce_sync).raises(WaterDrop::Errors::ProduceError)
    produce(topic, "hello", key: "k1")
  end

  after do
    Karafka::Web.config.mcp.changing_tools = []
    Karafka::Web.config.ui.topics.management.active = true
  end

  context "when changing tools are not enabled" do
    before { Karafka::Web.config.mcp.changing_tools = [] }

    it "is neither listed nor callable" do
      refute_includes(listed, described_class.name)
      assert_equal("Unknown tool: #{described_class.name}", rpc_error["message"])
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when all changing tools are enabled" do
    before { Karafka::Web.config.mcp.changing_tools = :all }

    it { assert_includes(listed, described_class.name) }
  end

  it "is annotated as a changing tool" do
    annotations = described_class.definition.fetch(:annotations)

    refute(annotations[:readOnlyHint])
    refute(annotations[:destructiveHint])
    refute(annotations[:idempotentHint])
  end
  let(:topic) { create_topic }
  let(:target_topic) { create_topic }
  let(:arguments) { { topic: topic, partition: 0, offset: 0, target_topic: target_topic } }
  let(:policy) { Karafka::Web.config.ui.policies.messages }
  let(:copies) { Karafka::Admin.read_topic(target_topic, 0, 10) }

  context "when the policy denies it" do
    before { policy.stubs(:republish?).returns(false) }

    it "refuses the call without republishing" do
      assert_equal("The messages policy denies republishing this message", rpc_error["message"])
      assert_empty(copies)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the source message does not exist" do
    let(:arguments) { { topic: topic, partition: 0, offset: 10, target_topic: target_topic } }

    it { assert_equal("No source message under these coordinates", rpc_error["message"]) }
  end

  context "when it targets the audit topic" do
    let(:arguments) { { topic: topic, partition: 0, offset: 0, target_topic: audit_topic } }

    it { assert_equal("The MCP audit topic cannot be changed through MCP", rpc_error["message"]) }
  end

  context "when the audit intent cannot be written" do
    before { Karafka::Web.producers.stubs(:fully_acked).returns(failing) }

    it "refuses the call without republishing" do
      assert_equal("Audit log is not available, the call was refused", rpc_error["message"])
      assert_empty(copies)
    end
  end

  context "when called" do
    it "sends a copy and audits it" do
      refute(result["isError"])
      assert_equal("hello", copies.first.raw_payload)
      assert_equal("k1", copies.first.key)
      assert_equal(%w[intent result], records.map { |record| record["type"] })
      assert_equal("ok", records.last["outcome"])
    end
  end

  context "when the requests policy denies the matching Web UI request" do
    let(:requested) { [] }

    before do
      Karafka::Web.config.ui.policies.requests
        .stubs(:allow?)
        .with { |env| requested << env.values_at("REQUEST_POST", "/explorer/messages/#{topic}/0/0/republish_INFO") }
        .returns(false)
    end

    it "refuses the call and writes the rejection" do
      assert_equal("The requests policy denies POST /explorer/messages/#{topic}/0/0/republish", rpc_error["message"])
      assert_equal(["POST", "/explorer/messages/#{topic}/0/0/republish"], requested.first)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the target topic does not exist" do
    let(:arguments) { { topic: topic, partition: 0, offset: 0, target_topic: generate_topic_name } }

    it "says so, as the Web UI does" do
      assert(result["isError"])
      assert_includes(result.dig("content", 0, "text"), "Target topic does not exist")
    end
  end
end
