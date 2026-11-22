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

    produce_many(topic, Array.new(10) { |i| i.to_s })
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
  let(:base_arguments) { { topic: topic, partition: 0, offset: 4 } }
  let(:arguments) { base_arguments.merge(confirm: true) }
  let(:policy) { Karafka::Web.config.ui.policies.messages }
  let(:low) { Karafka::Admin.read_watermark_offsets(topic, 0).first }

  context "when the default policy denies it" do
    it "refuses the call without deleting messages" do
      assert_equal(
        "The messages policy denies deleting messages of this partition",
        rpc_error["message"]
      )
      assert_equal(0, low)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the policy allows it" do
    before { policy.stubs(:delete_records?).returns(true) }

    context "when confirm is missing" do
      let(:arguments) { base_arguments }

      it "refuses the call without deleting messages" do
        assert_includes(rpc_error["message"], "confirm: true")
        assert_equal(0, low)
      end
    end

    context "when it is a dry run" do
      let(:arguments) { base_arguments.merge(dry_run: true) }

      it "describes the deletion without deleting messages" do
        change = result.dig("structuredContent", "change")

        assert_equal({ "from" => 0, "to" => 3, "count" => 4 }, change.slice("from", "to", "count"))
        assert_equal(0, low)
      end
    end

    context "when the offset is past the end of the partition" do
      let(:arguments) { base_arguments.merge(offset: 100, confirm: true) }

      it { assert(result["isError"]) }
    end

    context "when there is nothing below the offset" do
      let(:arguments) { base_arguments.merge(offset: 0, confirm: true) }

      it { assert(result["isError"]) }
    end

    context "when the audit intent cannot be written" do
      before { Karafka::Web.producers.stubs(:fully_acked).returns(failing) }

      it "refuses the call without deleting messages" do
        assert_equal("Audit log is not available, the call was refused", rpc_error["message"])
        assert_equal(0, low)
      end
    end

    context "when confirmed" do
      it "deletes the messages below the offset and audits it" do
        refute(result["isError"])
        assert_equal(4, low)
        assert_equal(%w[intent result], records.map { |record| record["type"] })
        assert_equal("ok", records.last["outcome"])
      end
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
      assert_equal("The requests policy denies DELETE /explorer/messages/#{topic}/0/4/delete", rpc_error["message"])
      assert_equal(["DELETE", "/explorer/messages/#{topic}/0/4/delete"], requested.first)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end
end
