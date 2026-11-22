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
  include McpToolsHelper

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
    refute(annotations[:destructiveHint])
    refute(annotations[:idempotentHint])
  end
  let(:cluster_topics) { Karafka::Admin.cluster_info.topics.map { |t| t[:topic_name] } }
  let(:topic) { generate_topic_name }
  let(:arguments) { { topic: topic, partitions: 2, replication_factor: 1 } }

  context "when topics management is disabled" do
    before { Karafka::Web.config.ui.topics.management.active = false }

    it "refuses the call without creating the topic" do
      assert_equal("Topics management is disabled", rpc_error["message"])
      refute_includes(cluster_topics, topic)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the Web UI form contract refuses it" do
    let(:arguments) { { topic: "..", partitions: 2, replication_factor: 1 } }

    it { assert(result["isError"]) }
  end

  context "when the audit intent cannot be written" do
    before { Karafka::Web.producers.stubs(:fully_acked).returns(failing) }

    it "refuses the call without creating the topic" do
      assert_equal("Audit log is not available, the call was refused", rpc_error["message"])
      refute_includes(cluster_topics, topic)
    end
  end

  context "when called" do
    it "creates the topic and audits it" do
      refute(result["isError"])
      assert_includes(cluster_topics, topic)
      assert_equal(2, Karafka::Web::Ui::Models::Topic.find(topic).partition_count)
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
      assert_equal("The requests policy denies POST /topics", rpc_error["message"])
      assert_equal(["POST", "/topics"], requested.first)
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when the topic name is internal and internal topics are hidden" do
    let(:topic) { "__#{generate_topic_name}" }

    it "creates it, as the Web UI does" do
      refute(result["isError"])
      assert_includes(cluster_topics, topic)
    end
  end
end
