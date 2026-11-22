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
    assert(annotations[:destructiveHint])
    assert(annotations[:idempotentHint])
  end
  let(:topic) { create_topic }
  let(:base_arguments) { { topic: topic, property: "retention.ms", value: "86400000" } }
  let(:arguments) { base_arguments.merge(confirm: true) }
  let(:retention) do
    Karafka::Web::Ui::Models::Topic.find(topic).configs.find { |c| c.name == "retention.ms" }.value
  end

  context "when topics management is disabled" do
    before { Karafka::Web.config.ui.topics.management.active = false }

    it "refuses the call without changing the config" do
      assert_equal("Topics management is disabled", rpc_error["message"])
      assert_equal("604800000", retention)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when confirm is missing" do
    let(:arguments) { base_arguments }

    it "refuses the call without changing the config" do
      assert_includes(rpc_error["message"], "confirm: true")
      assert_equal("604800000", retention)
    end
  end

  context "when it is a dry run" do
    let(:arguments) { base_arguments.merge(dry_run: true) }

    it "describes the change without changing the config" do
      change = result.dig("structuredContent", "change")

      assert_equal({ "from" => "604800000", "to" => "86400000" }, change.slice("from", "to"))
      assert_equal("604800000", retention)
    end
  end

  context "when the property does not exist" do
    let(:arguments) { base_arguments.merge(property: "unknown.property", confirm: true) }

    it { assert(result["isError"]) }
  end

  context "when the audit intent cannot be written" do
    before { Karafka::Web.producers.stubs(:fully_acked).returns(failing) }

    it "refuses the call without changing the config" do
      assert_equal("Audit log is not available, the call was refused", rpc_error["message"])
      assert_equal("604800000", retention)
    end
  end

  context "when called" do
    it "changes the property and audits it" do
      refute(result["isError"])
      assert_equal("86400000", retention)
      assert_equal(%w[intent result], records.map { |record| record["type"] })
      assert_equal("ok", records.last["outcome"])
    end
  end

  context "when the requests policy denies the matching Web UI request" do
    let(:requested) { [] }

    before do
      Karafka::Web.config.ui.policies.requests
        .stubs(:allow?)
        .with { |env| requested << env.values_at("REQUEST_METHOD", "PATH_INFO") }
        .returns(false)
    end

    it "refuses the call and writes the rejection" do
      assert_equal("The requests policy denies PUT /topics/#{topic}/config/retention.ms", rpc_error["message"])
      assert_equal(["PUT", "/topics/#{topic}/config/retention.ms"], requested.first)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the topic is internal and internal topics are hidden" do
    let(:arguments) { base_arguments.merge(topic: "__consumer_offsets", confirm: true) }

    it "refuses the call" do
      assert_equal("Internal topics are hidden in the Web UI", rpc_error["message"])
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the property is read-only" do
    before { Karafka::Admin::Configs::Config.any_instance.stubs(:read_only?).returns(true) }

    it "fails without changing the config" do
      assert(result["isError"])
      assert_equal("Property retention.ms is read-only", result.dig("content", 0, "text"))
      assert_equal("604800000", retention)
    end
  end
end
