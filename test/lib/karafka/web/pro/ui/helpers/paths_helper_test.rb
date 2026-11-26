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
  let(:helper) do
    helper_class = Class.new do
      include Karafka::Web::Ui::Helpers::PathsHelper
      include Karafka::Web::Pro::Ui::Helpers::PathsHelper

      attr_accessor :env, :current_action_name

      def initialize(env = {}, current_action_name = nil)
        @env = env
        @current_action_name = current_action_name
      end
    end

    helper_class.new(env, current_action_name)
  end

  let(:env) { { "SCRIPT_NAME" => "/web-ui" } }
  let(:current_action_name) { :show }

  describe "#explorer_path" do
    it "builds basic explorer paths" do
      result = helper.explorer_path("topics")

      assert_equal("/web-ui/explorer/topics", result)
    end

    it "handles multiple path components" do
      result = helper.explorer_path("topics", "test-topic", "partition", "0")

      assert_equal("/web-ui/explorer/topics/test-topic/partition/0", result)
    end

    it "compacts nil values from arguments" do
      result = helper.explorer_path("topics", nil, "test-topic", nil, "0")

      assert_equal("/web-ui/explorer/topics/test-topic/0", result)
    end

    it "handles nested array arguments" do
      result = helper.explorer_path(%w[topics test-topic], %w[partition 0])

      assert_equal("/web-ui/explorer/topics/test-topic/partition/0", result)
    end
  end

  describe "#explorer_topics_path" do
    it "builds topics explorer paths" do
      result = helper.explorer_topics_path("test-topic")

      assert_equal("/web-ui/explorer/topics/test-topic", result)
    end

    it "handles multiple arguments" do
      result = helper.explorer_topics_path("test-topic", "partition", "0")

      assert_equal("/web-ui/explorer/topics/test-topic/partition/0", result)
    end

    it "compacts nil values" do
      result = helper.explorer_topics_path("test-topic", nil, "0")

      assert_equal("/web-ui/explorer/topics/test-topic/0", result)
    end
  end

  describe "#explorer_messages_path" do
    it "builds messages explorer paths" do
      result = helper.explorer_messages_path("test-topic", "0", "100")

      assert_equal("/web-ui/explorer/messages/test-topic/0/100", result)
    end

    it "handles topic and partition only" do
      result = helper.explorer_messages_path("test-topic", "0")

      assert_equal("/web-ui/explorer/messages/test-topic/0", result)
    end

    it "compacts nil values" do
      result = helper.explorer_messages_path("test-topic", nil, "100")

      assert_equal("/web-ui/explorer/messages/test-topic/100", result)
    end
  end

  describe "#topics_path" do
    it "builds basic topics path" do
      result = helper.topics_path

      assert_equal("/web-ui/topics", result)
    end

    it "builds topics path with arguments" do
      result = helper.topics_path("test-topic", "details")

      assert_equal("/web-ui/topics/test-topic/details", result)
    end

    it "handles single topic argument" do
      result = helper.topics_path("test-topic")

      assert_equal("/web-ui/topics/test-topic", result)
    end
  end

  describe "#consumer_path" do
    it "builds consumer-specific paths" do
      result = helper.consumer_path("consumer-123", "details")

      assert_equal("/web-ui/consumers/consumer-123/details", result)
    end

    it "builds consumer path with just consumer ID" do
      result = helper.consumer_path("consumer-123")

      assert_equal("/web-ui/consumers/consumer-123", result)
    end

    it "handles multiple path components" do
      result = helper.consumer_path("consumer-123", "subscriptions", "topic-1")

      assert_equal("/web-ui/consumers/consumer-123/subscriptions/topic-1", result)
    end
  end

  describe "#scheduled_messages_explorer_path" do
    context "with all parameters" do
      it "builds complete scheduled messages explorer path" do
        result = helper.scheduled_messages_explorer_path(
          "scheduled-topic",
          "0",
          "100",
          "details"
        )

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic/0/100/details", result)
      end
    end

    context "with partial parameters" do
      it "builds path with topic name only" do
        result = helper.scheduled_messages_explorer_path("scheduled-topic")

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic", result)
      end

      it "builds path with topic and partition" do
        result = helper.scheduled_messages_explorer_path("scheduled-topic", "0")

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic/0", result)
      end

      it "builds path with topic, partition, and offset" do
        result = helper.scheduled_messages_explorer_path("scheduled-topic", "0", "100")

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic/0/100", result)
      end
    end

    context "with nil parameters" do
      it "compacts nil values correctly" do
        result = helper.scheduled_messages_explorer_path("topic", nil, "100", nil)

        assert_equal("/web-ui/scheduled_messages/explorer/topics/topic/100", result)
      end

      it "handles all nil parameters except topic" do
        result = helper.scheduled_messages_explorer_path("topic", nil, nil, nil)

        assert_equal("/web-ui/scheduled_messages/explorer/topics/topic", result)
      end

      it "handles completely nil parameters" do
        result = helper.scheduled_messages_explorer_path

        assert_equal("/web-ui/scheduled_messages/explorer/topics", result)
      end
    end
  end

  describe "edge cases" do
    context "with special characters in paths" do
      it "handles topic names with special characters" do
        result = helper.topics_path("test-topic_v1.0")

        assert_equal("/web-ui/topics/test-topic_v1.0", result)
      end

      it "handles consumer IDs with special characters" do
        result = helper.consumer_path("consumer-123_v2.0")

        assert_equal("/web-ui/consumers/consumer-123_v2.0", result)
      end
    end
  end
end
