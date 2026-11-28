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
  let(:result) { described_class.new(arguments).call }
  let(:arguments) { {} }
  let(:structured) { result.fetch(:structuredContent) }
  let(:names) { structured.fetch(:topics).map { |topic| topic[:topic_name] } }
  let(:dlq_topic) { create_topic(partitions: 2) }
  let(:other_topic) { create_topic }

  it { assert(described_class.messages?) }

  context "when messages tools are disabled" do
    it { refute(described_class.available?) }
  end

  context "when a routed topic has a dead letter queue" do
    before do
      dlq = dlq_topic
      source = other_topic

      draw_routes do
        topic source do
          consumer Class.new(Karafka::BaseConsumer)
          dead_letter_queue(topic: dlq)
        end
      end
    end

    it "lists it as on the DLQ page" do
      refute(result[:isError])
      assert_includes(names, dlq_topic)
      refute_includes(names, other_topic)
      assert_equal(2, structured[:topics].find { |topic| topic[:topic_name] == dlq_topic }[:partition_count])
      assert_equal(names.sort, names)
    end
  end

  context "when a topic matches the DLQ patterns" do
    let(:dlq_topic) { create_topic(topic_name: "it-#{SecureRandom.uuid}-dlq") }

    before do
      dlq_topic
      Karafka::Web.config.ui.stubs(:dlq_patterns).returns([/-dlq\z/])
    end

    it { assert_includes(names, dlq_topic) }
  end

  context "when arguments are given" do
    let(:arguments) { { "what" => 1 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
