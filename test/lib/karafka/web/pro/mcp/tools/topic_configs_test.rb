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
  let(:arguments) { { "topic_name" => described_topic } }
  let(:described_topic) { create_topic }
  let(:structured) { result.fetch(:structuredContent) }
  let(:configs) { structured.fetch(:configs) }

  context "when the topic exists" do
    before do
      Karafka::Admin::Configs.alter(
        Karafka::Admin::Configs::Resource.new(type: :topic, name: described_topic).tap do |resource|
          resource.set("retention.ms", "86400000")
        end
      )
    end

    it "returns its configs sorted by name" do
      refute(result[:isError])
      assert_equal(described_topic, structured[:topic_name])
      assert_equal(configs.map { |config| config[:name] }.sort, configs.map { |config| config[:name] })
      assert_equal(%w[configs.value], structured[:untrusted_fields])
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end

    it "returns the config details as on the Web UI" do
      retention = configs.find { |config| config[:name] == "retention.ms" }

      assert_equal("86400000", retention[:value])
      assert_equal(:dynamic_topic_config, retention[:source])
      refute(retention[:default])
      refute(retention[:sensitive])
      refute(retention[:read_only])
      assert_includes(retention[:synonyms], "retention.ms")
    end

    it "marks an untouched config as default" do
      assert(configs.find { |config| config[:name] == "segment.bytes" }[:default])
    end
  end

  context "when configs are read-only or sensitive" do
    let(:flagged) do
      [
        Karafka::Admin::Configs::Config.new(name: "a.read.only", value: "1", read_only: 1),
        Karafka::Admin::Configs::Config.new(name: "b.sensitive", value: nil, sensitive: 1)
      ]
    end

    before do
      Karafka::Web::Pro::Ui::Models::Cluster::Topic.any_instance.stubs(:configs).returns(flagged)
    end

    it "maps each flag from its own config field" do
      read_only, sensitive = configs

      assert_equal([true, false, false], read_only.values_at(:read_only, :sensitive, :default))
      assert_equal([false, true, false], sensitive.values_at(:read_only, :sensitive, :default))
      assert_nil(sensitive[:value])
    end
  end

  context "when the topic does not exist" do
    let(:arguments) { { "topic_name" => generate_topic_name } }

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "does not exist")
    end
  end

  context "when the topic is internal and internal topics are hidden" do
    let(:described_topic) { create_topic(topic_name: "__#{generate_topic_name}") }

    it "answers as for a topic that does not exist" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "Topic #{described_topic} does not exist")
    end
  end

  context "when the topic is internal and internal topics are visible" do
    let(:described_topic) { create_topic(topic_name: "__#{generate_topic_name}") }

    before { Karafka::Web.config.ui.visibility.internal_topics = true }

    after { Karafka::Web.config.ui.visibility.internal_topics = false }

    it { refute(result[:isError]) }
  end

  context "when Kafka refuses the request" do
    before do
      Karafka::Web::Ui::Lib::Admin
        .stubs(:topic_info)
        .raises(Rdkafka::RdkafkaError.new(Rdkafka::Bindings::RD_KAFKA_RESP_ERR__TIMED_OUT))
    end

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "Kafka request failed")
    end
  end

  context "when topic name is missing" do
    let(:arguments) { {} }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end

  context "when topic name is not a Kafka topic name" do
    let(:arguments) { { "topic_name" => "../topics" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
