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
  let(:consumer_group_id) { "example_app6_app" }
  let(:topic) { "default" }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }
  let(:base_arguments) { { consumer_group_id: consumer_group_id, topic: topic, partition: 0, reset_attempts: true } }
  let(:arguments) { base_arguments }
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
    Karafka::Web.config.topics.consumers.commands.name = commands_topic
    Karafka::Web.config.commanding.active = true
    Karafka::Web.config.topics.consumers.states.name = states_topic
    Karafka::Web.config.topics.consumers.reports.name = reports_topic

    produce(states_topic, Fixtures.consumers_states_file)
    produce(reports_topic, Fixtures.consumers_reports_file)
  end

  after do
    Karafka::Web.config.mcp.changing_tools = []
    Karafka::Web.config.commanding.active = false
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
    assert(annotations[:idempotentHint])
  end
  let(:commands_topic) { create_topic }
  let(:commands) do
    Karafka::Admin.read_topic(commands_topic, 0, 10).map(&:payload)
  end

  context "when commanding is disabled" do
    before { Karafka::Web.config.commanding.active = false }

    it "refuses the call without sending a command" do
      assert_equal("Commanding is disabled", rpc_error["message"])
      assert_empty(commands)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the audit intent cannot be written" do
    before { Karafka::Web.producers.stubs(:fully_acked).returns(failing) }

    it "refuses the call without sending a command" do
      assert_equal("Audit log is not available, the call was refused", rpc_error["message"])
      assert_empty(commands)
    end
  end

  context "when called" do
    it "sends the same command as the Web UI action" do
      refute(result["isError"])
      sleep(1)
      command = commands.last

      assert_equal({
        name: "partitions.resume",
        consumer_group_id: consumer_group_id,
        topic: topic,
        partition_id: 0,
        reset_attempts: true
      }, command[:command])
      assert_equal({ consumer_group_id: consumer_group_id, topic: topic, partition_id: 0 }, command[:matchers])
    end

    it "writes the intent and the outcome to the audit log" do
      refute(result["isError"])
      assert_equal(%w[intent result], records.map { |record| record["type"] })
      assert_equal("ok", records.last["outcome"])
    end
  end

  context "when the requests policy denies the matching Web UI request" do
    let(:requested) { [] }

    before do
      Karafka::Web.config.ui.policies.requests
        .stubs(:allow?)
        .with { |env| requested << env.values_at("REQUEST_DELETE", "/consumers/partitions/#{consumer_group_id}/#{topic}/0/pause_INFO") }
        .returns(false)
    end

    it "refuses the call and writes the rejection" do
      assert_equal("The requests policy denies DELETE /consumers/partitions/#{consumer_group_id}/#{topic}/0/pause", rpc_error["message"])
      assert_equal(["DELETE", "/consumers/partitions/#{consumer_group_id}/#{topic}/0/pause"], requested.first)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when consumers do not report the target" do
    let(:consumer_group_id) { "unknown-group" }

    it "fails without sending a command" do
      assert(result["isError"])
      assert_includes(result.dig("content", 0, "text"), "Consumers do not report")
      assert_empty(commands)
    end
  end
end
