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

  context "when a routed consumer group has a committed offset" do
    let(:described_topic) { create_topic }
    let(:described_group) { "it-describe-#{SecureRandom.uuid}" }

    before do
      group = described_group
      topic_name = described_topic
      draw_routes do
        consumer_group group do
          topic topic_name do
            consumer Karafka::BaseConsumer
          end
        end
      end

      Karafka::Admin.seek_consumer_group(described_group, described_topic => { 0 => 0 })
    end

    it "describes it without members" do
      refute(result[:isError])

      group = structured.fetch(:consumer_groups).find { |cg| cg[:group_id] == described_group }

      assert_equal(:empty, group[:state])
      assert_empty(group[:members])
      assert_includes(group.keys, :coordinator)
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end
  end

  context "when a routed consumer group has a live member" do
    let(:described_topic) { create_topic(partitions: 2) }
    let(:described_group) { "it-describe-#{SecureRandom.uuid}" }
    let(:member) do
      Rdkafka::Config.new(
        "bootstrap.servers": "127.0.0.1:9092",
        "group.id": described_group
      ).consumer
    end

    before do
      group = described_group
      topic_name = described_topic
      draw_routes do
        consumer_group group do
          topic topic_name do
            consumer Karafka::BaseConsumer
          end
        end
      end

      member.subscribe(described_topic)
      member.poll(100) while member.assignment.empty?
    end

    after { member.close }

    it "describes its member with the assigned partitions" do
      group = structured.fetch(:consumer_groups).find { |cg| cg[:group_id] == described_group }

      assert_equal(:stable, group[:state])
      assert_equal(1, group[:members].size)
      assert_equal({ described_topic => [0, 1] }, group[:members].first[:assignment])
    end
  end

  context "when the routing has a share group" do
    let(:share_topic) { create_topic }
    let(:share_group_id) { "it-share-#{SecureRandom.uuid}" }

    before do
      group = share_group_id
      topic_name = share_topic
      draw_routes do
        share_group group do
          topic topic_name do
            consumer Karafka::ShareConsumer
          end
        end
      end
    end

    it "does not describe it as a consumer group" do
      refute(result[:isError])

      group_ids = structured.fetch(:consumer_groups).map { |cg| cg[:group_id] }

      refute_includes(group_ids, share_group_id)
    end
  end

  context "when Kafka refuses the request" do
    before do
      Karafka::Admin
        .stubs(:describe_consumer_groups)
        .raises(Rdkafka::RdkafkaError.new(Rdkafka::Bindings::RD_KAFKA_RESP_ERR__TIMED_OUT))
    end

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "Kafka request failed")
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "topic" => "test" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
