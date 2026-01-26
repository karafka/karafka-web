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

  let(:consumer_group_id) { SecureRandom.uuid }
  let(:topic) { SecureRandom.uuid }
  let(:command) { build_command(consumer_group_id, topic) }

  # Helper to build command with proper structure
  def build_command(group_id, topic_name)
    instance_double(
      Karafka::Web::Pro::Commanding::Request,
      to_h: { consumer_group_id: group_id, topic: topic_name },
      "[]": ->(key) { { consumer_group_id: group_id, topic: topic_name }[key] }
    ).tap do |cmd|
      allow(cmd).to receive(:[]) do |key|
        { consumer_group_id: group_id, topic: topic_name }[key]
      end
    end
  end

  describe "#<<" do
    it "adds command to the tracker" do
      tracker << command

      tracker.each_for(consumer_group_id, topic) do |stored_command|
        expect(stored_command).to eq(command)
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

        expect(commands).to eq([command, command2])
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

        expect(commands).to eq([command])
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

        expect(commands).to eq([command])
      end
    end
  end

  describe "#each_for" do
    before { tracker << command }

    it "yields each command for given consumer group and topic" do
      expect { |b| tracker.each_for(consumer_group_id, topic, &b) }
        .to yield_with_args(command)
    end

    it "removes processed commands after iteration" do
      tracker.each_for(consumer_group_id, topic) { nil }

      commands = []
      tracker.each_for(consumer_group_id, topic) do |cmd|
        commands << cmd
      end

      expect(commands).to be_empty
    end

    context "when no commands exist for consumer group and topic" do
      let(:non_existent_group) { SecureRandom.uuid }
      let(:non_existent_topic) { SecureRandom.uuid }

      it "yields nothing for non-existent consumer group" do
        expect { |b| tracker.each_for(non_existent_group, topic, &b) }
          .not_to yield_control
      end

      it "yields nothing for non-existent topic" do
        expect { |b| tracker.each_for(consumer_group_id, non_existent_topic, &b) }
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
              tracker << build_command(consumer_group_id, topic)
              tracker.each_for(consumer_group_id, topic) { nil }
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
