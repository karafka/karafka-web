# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:tracker) { described_class.instance }

  let(:subscription_group_id) { SecureRandom.uuid }
  let(:command) { build_command(subscription_group_id) }

  # Helper to build command with proper structure
  def build_command(group_id)
    instance_double(
      Karafka::Web::Pro::Commanding::Request,
      to_h: { subscription_group_id: group_id },
      '[]': group_id
    )
  end

  describe '#<<' do
    it 'adds command to the tracker' do
      tracker << command

      tracker.each_for(subscription_group_id) do |stored_command|
        expect(stored_command).to eq(command)
      end
    end

    context 'when adding multiple commands for same group' do
      let(:command2) { build_command(subscription_group_id) }

      it 'preserves order of commands' do
        commands = []
        tracker << command
        tracker << command2

        tracker.each_for(subscription_group_id) do |stored_command|
          commands << stored_command
        end

        expect(commands).to eq([command, command2])
      end
    end

    context 'when adding commands for different groups' do
      let(:other_group_id) { SecureRandom.uuid }
      let(:other_command) { build_command(other_group_id) }

      it 'keeps commands separated by group' do
        tracker << command
        tracker << other_command

        commands = []
        tracker.each_for(subscription_group_id) do |stored_command|
          commands << stored_command
        end

        expect(commands).to eq([command])
      end
    end
  end

  describe '#each_for' do
    before { tracker << command }

    it 'yields each command for given subscription group' do
      expect { |b| tracker.each_for(subscription_group_id, &b) }
        .to yield_with_args(command)
    end

    it 'removes processed commands after iteration' do
      tracker.each_for(subscription_group_id) {}

      commands = []
      tracker.each_for(subscription_group_id) do |cmd|
        commands << cmd
      end

      expect(commands).to be_empty
    end

    context 'when no commands exist for group' do
      let(:non_existent_group) { SecureRandom.uuid }

      it 'yields nothing' do
        expect { |b| tracker.each_for(non_existent_group, &b) }
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
              tracker << build_command(subscription_group_id)
              tracker.each_for(subscription_group_id) {}
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
