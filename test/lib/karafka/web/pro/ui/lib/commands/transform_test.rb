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
  let(:consumer_group_id) { "cg" }
  let(:topic) { "orders" }
  let(:partition_id) { 3 }

  describe "#partition_seek" do
    let(:data) do
      {
        consumer_group_id: consumer_group_id,
        topic: topic,
        partition_id: partition_id,
        offset: 42,
        prevent_overtaking: true,
        force_resume: false
      }
    end

    let(:result) { described_class.partition_seek(data) }

    it "targets the seek command" do
      assert_equal("partitions.seek", result[:name])
    end

    it "builds the payload verbatim" do
      payload = result[:payload]

      assert_equal(consumer_group_id, payload[:consumer_group_id])
      assert_equal(topic, payload[:topic])
      assert_equal(partition_id, payload[:partition_id])
      assert_equal(42, payload[:offset])
      assert(payload[:prevent_overtaking])
      refute(payload[:force_resume])
    end

    it "scopes the matchers to the single partition" do
      assert_equal(
        { consumer_group_id: consumer_group_id, topic: topic, partition_id: partition_id },
        result[:matchers]
      )
    end
  end

  describe "#partition_pause" do
    let(:data) do
      {
        consumer_group_id: consumer_group_id,
        topic: topic,
        partition_id: partition_id,
        duration: 60,
        prevent_override: true
      }
    end

    let(:result) { described_class.partition_pause(data) }

    it "targets the pause command" do
      assert_equal("partitions.pause", result[:name])
    end

    it "converts the duration from seconds to milliseconds" do
      assert_equal(60_000, result[:payload][:duration])
    end

    it "carries the prevent_override flag" do
      assert(result[:payload][:prevent_override])
    end

    it "scopes the matchers to the single partition" do
      assert_equal(partition_id, result[:matchers][:partition_id])
    end
  end

  describe "#partition_resume" do
    let(:data) do
      {
        consumer_group_id: consumer_group_id,
        topic: topic,
        partition_id: partition_id,
        reset_attempts: true
      }
    end

    let(:result) { described_class.partition_resume(data) }

    it "targets the resume command" do
      assert_equal("partitions.resume", result[:name])
    end

    it "carries the reset_attempts flag" do
      assert(result[:payload][:reset_attempts])
    end

    it "scopes the matchers to the single partition" do
      assert_equal(partition_id, result[:matchers][:partition_id])
    end
  end

  describe "#topic_pause" do
    let(:data) do
      {
        consumer_group_id: consumer_group_id,
        topic: topic,
        duration: 5,
        prevent_override: false
      }
    end

    let(:result) { described_class.topic_pause(data) }

    it "targets the topic pause command" do
      assert_equal("topics.pause", result[:name])
    end

    it "converts the duration from seconds to milliseconds" do
      assert_equal(5_000, result[:payload][:duration])
    end

    it "scopes the matchers to the whole topic (no partition)" do
      assert_equal({ consumer_group_id: consumer_group_id, topic: topic }, result[:matchers])
      refute(result[:payload].key?(:partition_id))
    end
  end

  describe "#topic_resume" do
    let(:data) do
      {
        consumer_group_id: consumer_group_id,
        topic: topic,
        reset_attempts: false
      }
    end

    let(:result) { described_class.topic_resume(data) }

    it "targets the topic resume command" do
      assert_equal("topics.resume", result[:name])
    end

    it "carries the reset_attempts flag" do
      refute(result[:payload][:reset_attempts])
    end

    it "scopes the matchers to the whole topic (no partition)" do
      assert_equal({ consumer_group_id: consumer_group_id, topic: topic }, result[:matchers])
    end
  end
end
