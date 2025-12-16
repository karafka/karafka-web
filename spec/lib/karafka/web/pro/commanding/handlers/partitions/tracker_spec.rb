# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:tracker) { described_class.instance }

  let(:consumer_group_id) { 'test_consumer_group' }
  let(:topic) { 'test_topic' }
  let(:partition_id) { 0 }
  let(:command) { build_command(consumer_group_id, topic, partition_id) }

  # Helper to build command with proper structure
  def build_command(cg_id, topic_name, part_id)
    instance_double(
      Karafka::Web::Pro::Commanding::Request,
      to_h: { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id },
      '[]': ->(key) { { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id }[key] }
    ).tap do |cmd|
      allow(cmd).to receive(:[]) do |key|
        { consumer_group_id: cg_id, topic: topic_name, partition_id: part_id }[key]
      end
    end
  end

  describe '#<<' do
    it 'adds command to the tracker' do
      tracker << command

      tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
        expect(stored_command).to eq(command)
      end
    end

    context 'when adding multiple commands for same partition' do
      let(:command2) { build_command(consumer_group_id, topic, partition_id) }

      it 'preserves order of commands' do
        commands = []
        tracker << command
        tracker << command2

        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        expect(commands).to eq([command, command2])
      end
    end

    context 'when adding commands for different partitions' do
      let(:other_partition_id) { 1 }
      let(:other_command) { build_command(consumer_group_id, topic, other_partition_id) }

      it 'keeps commands separated by partition' do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        expect(commands).to eq([command])
      end
    end

    context 'when adding commands for different topics' do
      let(:other_topic) { 'other_topic' }
      let(:other_command) { build_command(consumer_group_id, other_topic, partition_id) }

      it 'keeps commands separated by topic' do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(consumer_group_id, topic, partition_id) do |stored_command|
          commands << stored_command
        end

        expect(commands).to eq([command])
      end
    end

    context 'when adding commands for different consumer groups' do
      let(:other_cg_id) { 'other_consumer_group' }
      let(:other_command) { build_command(other_cg_id, topic, partition_id) }

      it 'keeps commands separated by consumer group' do
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

  describe '#each_for' do
    before { tracker << command }

    it 'yields each command for given consumer group, topic, and partition' do
      expect { |b| tracker.each_for(consumer_group_id, topic, partition_id, &b) }
        .to yield_with_args(command)
    end

    it 'removes processed commands after iteration' do
      tracker.each_for(consumer_group_id, topic, partition_id) { nil }

      commands = []
      tracker.each_for(consumer_group_id, topic, partition_id) do |cmd|
        commands << cmd
      end

      expect(commands).to be_empty
    end

    context 'when no commands exist for the key' do
      let(:non_existent_cg) { 'non_existent_group' }

      it 'yields nothing' do
        expect { |b| tracker.each_for(non_existent_cg, topic, partition_id, &b) }
          .not_to yield_control
      end
    end

    context 'when called concurrently' do
      let(:threads_count) { 10 }
      let(:iterations) { 100 }

      it 'handles concurrent access without racing conditions' do
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

  describe '.instance' do
    it 'is a singleton' do
      expect { described_class.new }.to raise_error(NoMethodError)
    end
  end
end
