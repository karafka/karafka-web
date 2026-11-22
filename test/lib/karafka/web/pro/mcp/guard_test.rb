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
  let(:audit_topic) { Karafka::Web.config.topics.mcp_audit.name }
  let(:other_topic) { generate_topic_name }
  let(:tool_class) do
    operation = tool_operation

    Class.new(Karafka::Web::Pro::Mcp::Tools::Base) do
      tool(
        "karafka_test_change",
        "Test changing tool",
        contract: Karafka::Web::Pro::Mcp::Tools::Contracts::NoArguments.new,
        operation: operation
      )

      attr_writer :topics

      def topics
        @topics || []
      end
    end
  end
  let(:tool) { tool_class.new({}) }

  Karafka::Web::Pro::Mcp::Guard::OPERATIONS.each do |operation|
    context "when #{operation} tool targets the audit topic" do
      let(:tool_operation) { operation }

      before { tool.topics = [other_topic, audit_topic] }

      it do
        error = assert_raises(Karafka::Web::Errors::Mcp::PolicyDeniedError) do
          described_class.check!(tool)
        end

        assert_equal("The MCP audit topic cannot be changed through MCP", error.message)
      end
    end

    context "when #{operation} tool targets other topics" do
      let(:tool_operation) { operation }

      before { tool.topics = [other_topic] }

      it { assert_nil(described_class.check!(tool)) }
    end
  end

  context "when tool declares an unknown operation" do
    let(:tool_operation) { :truncate }

    it do
      assert_raises(Karafka::Web::Errors::Mcp::PolicyDeniedError) { described_class.check!(tool) }
    end
  end

  context "when audit topic name is changed" do
    let(:tool_operation) { :produce }

    before do
      Karafka::Web.config.topics.mcp_audit.name = other_topic
      tool.topics = [other_topic]
    end

    it do
      assert_raises(Karafka::Web::Errors::Mcp::PolicyDeniedError) { described_class.check!(tool) }
    end
  end
end
