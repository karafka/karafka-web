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

RSpec.describe_current do
  subject(:tracker) { described_class.instance }

  let(:consumer_group_id) { "test_consumer_group" }
  let(:topic) { "test_topic" }
  let(:partition_id) { 0 }
  let(:command) { build_command(consumer_group_id, topic, partition_id) }

  before { tracker.clear! }

  # Helper to build command with proper structure
  def build_command(cg_id, topic_name, part_id)
    instance_double(
      Karafka::Web::Pro::Commanding::Request,
      to_h: { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id },
      "[]": ->(key) { { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id }[key] }
    ).tap do |cmd|
      allow(cmd).to receive(:[]) do |key|
        { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id }[key]
      end
    end
  end

  describe "#<<" do
    it "adds command to the tracker" do
      tracker << command

      tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
        expect(stored_command).to eq(command)
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

        expect(commands).to eq([command, command2])
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

        expect(commands).to eq([command])
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

        expect(commands).to eq([command])
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

        expect(commands).to eq([command])
      end
    end
  end

  describe "#each_for" do
    before { tracker << command }

    it "yields each command for given consumer group, topic, and partition" do
      expect { |b| tracker.each_for(consumer_group_id, topic, partition_id, &b) }
        .to yield_with_args(command)
    end

    it "removes processed commands after iteration" do
      tracker.each_for(consumer_group_id, topic, partition_id) { nil }

      commands = []
      tracker.each_for(consumer_group_id, topic, partition_id) do |cmd|
        commands << cmd
      end

      expect(commands).to be_empty
    end

    context "when no commands exist for the key" do
      let(:non_existent_cg) { "non_existent_group" }

      it "yields nothing" do
        expect { |b| tracker.each_for(non_existent_cg, topic, partition_id, &b) }
          .not_to yield_control
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

        expect { threads.each(&:join) }.not_to raise_error
      end
    end
  end

  describe "#partition_ids_for" do
    context "when no commands exist" do
      it "returns an empty array" do
        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([])
      end
    end

    context "when commands exist for a single partition" do
      before { tracker << command }

      it "returns array with that partition id" do
        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([partition_id])
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
        expect(result).to contain_exactly(partition_id, partition_id2, partition_id3)
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
        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([partition_id])
        expect(tracker.partition_ids_for(consumer_group_id, other_topic)).to eq([99])
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
        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([partition_id])
        expect(tracker.partition_ids_for(other_cg_id, topic)).to eq([99])
      end
    end

    context "when commands are removed via each_for" do
      before { tracker << command }

      it "removes partition id from the index" do
        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([partition_id])

        tracker.each_for(consumer_group_id, topic, partition_id) { nil }

        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([])
      end
    end

    context "when multiple commands exist for same partition" do
      let(:command2) { build_command(consumer_group_id, topic, partition_id) }

      before do
        tracker << command
        tracker << command2
      end

      it "returns partition id only once" do
        expect(tracker.partition_ids_for(consumer_group_id, topic)).to eq([partition_id])
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

        expect { threads.each(&:join) }.not_to raise_error
      end
    end
  end

  describe ".instance" do
    it "is a singleton" do
      expect { described_class.new }.to raise_error(NoMethodError)
    end
  end
end
