# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:tracker) { described_class.instance }

  let(:consumer_group_id) { "test_consumer_group" }
  let(:topic) { "test_topic" }
  let(:partition_id) { 0 }
  let(:command) { build_command(consumer_group_id, topic, partition_id) }

  before { tracker.clear! }

  # Helper to build command with proper structure
  def build_command(cg_id, topic_name, part_id)
    data = { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id }
    cmd = stub(to_h: data)
    cmd.define_singleton_method(:[]) { |key| data[key] }
    cmd
  end

  describe "#<<" do
    it "adds command to the tracker" do
      tracker << command

      tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
        assert_equal(command, stored_command)
      end
    end

    context "when adding multiple commands for same partition" do
      let(:command2) { build_command(consumer_group_id, topic, partition_id) }

      it "preserves order of commands" do
        commands = []
        tracker << command
        tracker << command2

        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        assert_equal([command, command2], commands)
      end
    end

    context "when adding commands for different partitions" do
      let(:other_partition_id) { 1 }
      let(:other_command) { build_command(consumer_group_id, topic, other_partition_id) }

      it "keeps commands separated by partition" do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        assert_equal([command], commands)
      end
    end

    context "when adding commands for different topics" do
      let(:other_topic) { "other_topic" }
      let(:other_command) { build_command(consumer_group_id, other_topic, partition_id) }

      it "keeps commands separated by topic" do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        assert_equal([command], commands)
      end
    end

    context "when adding commands for different consumer groups" do
      let(:other_cg_id) { "other_consumer_group" }
      let(:other_command) { build_command(other_cg_id, topic, partition_id) }

      it "keeps commands separated by consumer group" do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        assert_equal([command], commands)
      end
    end
  end

  describe "#each_for" do
    before { tracker << command }

    it "yields each command for given consumer group, topic, and partition" do
      yielded = []
      tracker.each_for(consumer_group_id, topic, partition_id) { |cmd| yielded << cmd }

      assert_equal([command], yielded)
    end

    it "removes processed commands after iteration" do
      tracker.each_for(consumer_group_id, topic, partition_id) { nil }

      commands = []
      tracker.each_for(consumer_group_id, topic, partition_id) do |cmd|
        commands << cmd
      end

      assert_empty(commands)
    end

    context "when no commands exist for the key" do
      let(:non_existent_cg) { "non_existent_group" }

      it "yields nothing" do
        yielded = false
        tracker.each_for(non_existent_cg, topic, partition_id) { yielded = true }

        refute(yielded)
      end
    end

    context "when called concurrently" do
      let(:threads_count) { 10 }
      let(:iterations) { 100 }

      it "handles concurrent access without racing conditions" do
        threads = Array.new(threads_count) do
          Thread.new do
            iterations.times do
              tracker << build_command(consumer_group_id, topic, partition_id)
              tracker.each_for(consumer_group_id, topic, partition_id) { nil }
            end
          end
        end

        threads.each(&:join)
      end
    end
  end

  describe "#partition_ids_for" do
    context "when no commands exist" do
      it "returns an empty array" do
        assert_equal([], tracker.partition_ids_for(consumer_group_id, topic))
      end
    end

    context "when commands exist for a single partition" do
      before { tracker << command }

      it "returns array with that partition id" do
        assert_equal([partition_id], tracker.partition_ids_for(consumer_group_id, topic))
      end
    end

    context "when commands exist for multiple partitions" do
      let(:partition_id2) { 5 }
      let(:partition_id3) { 10 }
      let(:command2) { build_command(consumer_group_id, topic, partition_id2) }
      let(:command3) { build_command(consumer_group_id, topic, partition_id3) }

      before do
        tracker << command
        tracker << command2
        tracker << command3
      end

      it "returns all partition ids" do
        result = tracker.partition_ids_for(consumer_group_id, topic)

        assert_equal([partition_id, partition_id2, partition_id3].sort, result.sort)
      end
    end

    context "when commands exist for different topics" do
      let(:other_topic) { "other_topic" }
      let(:other_command) { build_command(consumer_group_id, other_topic, 99) }

      before do
        tracker << command
        tracker << other_command
      end

      it "returns only partition ids for the specified topic" do
        assert_equal([partition_id], tracker.partition_ids_for(consumer_group_id, topic))
        assert_equal([99], tracker.partition_ids_for(consumer_group_id, other_topic))
      end
    end

    context "when commands exist for different consumer groups" do
      let(:other_cg_id) { "other_consumer_group" }
      let(:other_command) { build_command(other_cg_id, topic, 99) }

      before do
        tracker << command
        tracker << other_command
      end

      it "returns only partition ids for the specified consumer group" do
        assert_equal([partition_id], tracker.partition_ids_for(consumer_group_id, topic))
        assert_equal([99], tracker.partition_ids_for(other_cg_id, topic))
      end
    end

    context "when commands are removed via each_for" do
      before { tracker << command }

      it "removes partition id from the index" do
        assert_equal([partition_id], tracker.partition_ids_for(consumer_group_id, topic))

        tracker.each_for(consumer_group_id, topic, partition_id) { nil }

        assert_equal([], tracker.partition_ids_for(consumer_group_id, topic))
      end
    end

    context "when multiple commands exist for same partition" do
      let(:command2) { build_command(consumer_group_id, topic, partition_id) }

      before do
        tracker << command
        tracker << command2
      end

      it "returns partition id only once" do
        assert_equal([partition_id], tracker.partition_ids_for(consumer_group_id, topic))
      end
    end

    context "when called concurrently" do
      let(:threads_count) { 10 }
      let(:iterations) { 100 }

      it "handles concurrent access without racing conditions" do
        threads = Array.new(threads_count) do
          Thread.new do
            iterations.times do |i|
              tracker << build_command(consumer_group_id, topic, i)
              tracker.partition_ids_for(consumer_group_id, topic)
              tracker.each_for(consumer_group_id, topic, i) { nil }
            end
          end
        end

        threads.each(&:join)
      end
    end
  end

  describe ".instance" do
    it "is a singleton" do
      assert_raises(NoMethodError) { described_class.new }
    end
  end
end
