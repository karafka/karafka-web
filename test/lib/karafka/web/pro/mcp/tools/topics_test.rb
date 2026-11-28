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
  let(:topic_names) { structured.fetch(:topics).map { |topic| topic[:topic_name] } }

  context "when the cluster has topics" do
    let(:listed_topic) { create_topic(partitions: 2) }

    before { listed_topic }

    it "lists them sorted with their partition count" do
      refute(result[:isError])

      topic = structured.fetch(:topics).find { |details| details[:topic_name] == listed_topic }

      assert_equal({ topic_name: listed_topic, partition_count: 2 }, topic)
      assert_equal(topic_names.sort, topic_names)
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end
  end

  context "when internal topics are hidden" do
    let(:internal_topic) { create_topic(topic_name: "__#{generate_topic_name}") }

    before { internal_topic }

    it "does not list them" do
      refute_includes(topic_names, internal_topic)
      assert(topic_names.none? { |name| name.start_with?("__") })
    end
  end

  context "when internal topics are visible" do
    let(:internal_topic) { create_topic(topic_name: "__#{generate_topic_name}") }

    before do
      internal_topic
      Karafka::Web.config.ui.visibility.internal_topics = true
    end

    after { Karafka::Web.config.ui.visibility.internal_topics = false }

    it { assert_includes(topic_names, internal_topic) }
  end

  context "when Kafka refuses the request" do
    before do
      Karafka::Web::Ui::Models::Cluster::Info
        .stubs(:fetch)
        .raises(Rdkafka::RdkafkaError.new(Rdkafka::Bindings::RD_KAFKA_RESP_ERR__TIMED_OUT))
    end

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "Kafka request failed")
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "topic_name" => "test" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
