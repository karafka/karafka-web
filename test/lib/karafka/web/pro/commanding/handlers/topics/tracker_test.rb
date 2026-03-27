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
  let(:tracker) { described_class.instance }

  let(:consumer_group_id) { SecureRandom.uuid }
  let(:topic) { SecureRandom.uuid }
  let(:command) { build_command(consumer_group_id, topic) }

  # Helper to build command with proper structure
  def build_command(group_id, topic_name)
    data = { consumer_group_id: group_id, topic: topic_name }
    cmd = stub(to_h: data)
    cmd.define_singleton_method(:[]) { |key| data[key] }
    cmd
  end

  describe "#<<" do
    it "adds command to the tracker" do
      tracker << command

      tracker.each_for(consumer_group_id, topic) do |stored_command|
        assert_equal(command, stored_command)
      end
    end

    context "when adding multiple commands for same group and topic" do
      let(:command2) { build_command(consumer_group_id, topic) }

      it "preserves order of commands" do
        commands = []
        tracker << command
        tracker << command2

        tracker.each_for(consumer_group_id, topic) do |stored_command|
          commands << stored_command
        end

        assert_equal([command, command2], commands)
      end
    end

    context "when adding commands for different consumer groups" do
      let(:other_group_id) { SecureRandom.uuid }
      let(:other_command) { build_command(other_group_id, topic) }

      it "keeps commands separated by consumer group" do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic) do |stored_command|
          commands << stored_command
        end

        assert_equal([command], commands)
      end
    end

    context "when adding commands for different topics" do
      let(:other_topic) { SecureRandom.uuid }
      let(:other_command) { build_command(consumer_group_id, other_topic) }

      it "keeps commands separated by topic" do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic) do |stored_command|
          commands << stored_command
        end

        assert_equal([command], commands)
      end
    end
  end

  describe "#each_for" do
    before { tracker << command }

    it "yields each command for given consumer group and topic" do
      yielded = []
      tracker.each_for(consumer_group_id, topic) { |cmd| yielded << cmd }

      assert_equal([command], yielded)
    end

    it "removes processed commands after iteration" do
      tracker.each_for(consumer_group_id, topic) { nil }

      commands = []
      tracker.each_for(consumer_group_id, topic) do |cmd|
        commands << cmd
      end

      assert_empty(commands)
    end

    context "when no commands exist for consumer group and topic" do
      let(:non_existent_group) { SecureRandom.uuid }
      let(:non_existent_topic) { SecureRandom.uuid }

      it "yields nothing for non-existent consumer group" do
        yielded = false
        tracker.each_for(non_existent_group, topic) { yielded = true }

        refute(yielded)
      end

      it "yields nothing for non-existent topic" do
        yielded = false
        tracker.each_for(consumer_group_id, non_existent_topic) { yielded = true }

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
              tracker << build_command(consumer_group_id, topic)
              tracker.each_for(consumer_group_id, topic) { nil }
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
