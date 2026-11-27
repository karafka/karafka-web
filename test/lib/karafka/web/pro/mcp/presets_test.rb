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

  let(:changing) do
    rpc("tools/list")
      .dig("result", "tools")
      .reject { |tool| tool.dig("annotations", "readOnlyHint") }
      .map { |tool| tool["name"] }
  end

  before { Karafka::Web.config.topics.mcp_audit.name = audit_topic }

  after { Karafka::Web.config.mcp.changing_tools = [] }

  it { assert_equal(%w[karafka_pause_partition], described_class.tools(%w[karafka_pause_partition])) }

  it "keeps the operate preset to the reversible tools" do
    assert_equal(
      %w[
        karafka_pause_partition
        karafka_resume_partition
        karafka_pause_topic
        karafka_resume_topic
        karafka_trace_process
        karafka_quiet_process
        karafka_trigger_recurring_task
        karafka_republish_message
      ],
      described_class.tools(:operate)
    )
  end

  context "when the operate preset is enabled" do
    before { Karafka::Web.config.mcp.changing_tools = :operate }

    it "lists exactly the preset tools" do
      assert_equal(described_class.tools(:operate).sort, changing.sort)
      assert_equal(described_class.names.sort, changing.sort)
    end

    it "lists no destructive tool" do
      rpc("tools/list").dig("result", "tools").each do |tool|
        refute(tool.dig("annotations", "destructiveHint"), tool["name"])
      end
    end
  end

  context "when one tool name is enabled" do
    before { Karafka::Web.config.mcp.changing_tools = %w[karafka_pause_partition] }

    let(:call) do
      rpc("tools/call", { name: "karafka_resume_partition", arguments: {} }).fetch("error")
    end

    it "lists only that changing tool and refuses the others" do
      assert_equal(%w[karafka_pause_partition], changing)
      assert_equal("Unknown tool: karafka_resume_partition", call["message"])
      assert_equal(%w[rejected], records.map { |record| record["outcome"] })
    end
  end

  context "when no changing tool is enabled" do
    it { assert_empty(changing) }
  end
end
