# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:command) { described_class.new(listener, client, request) }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }

  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      name: 'topics.pause',
      topic: topic_name,
      consumer_group_id: consumer_group_id,
      duration: duration,
      prevent_override: prevent_override
    )
  end

  let(:coordinators) { instance_double(Karafka::Processing::CoordinatorsBuffer) }
  let(:coordinator0) { instance_double(Karafka::Processing::Coordinator) }
  let(:coordinator1) { instance_double(Karafka::Processing::Coordinator) }
  let(:pause_tracker0) { instance_double(Karafka::TimeTrackers::Pause) }
  let(:pause_tracker1) { instance_double(Karafka::TimeTrackers::Pause) }
  let(:subscription_group) { instance_double(Karafka::Routing::SubscriptionGroup) }
  let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup) }
  let(:topic_partition_list) { { topic_name => [partition0, partition1] } }
  let(:partition0) { instance_double(Rdkafka::Consumer::Partition, partition: 0) }
  let(:partition1) { instance_double(Rdkafka::Consumer::Partition, partition: 1) }

  let(:topic_name) { 'test_topic' }
  let(:consumer_group_id) { 'test_consumer_group' }
  let(:duration) { 60_000 }
  let(:prevent_override) { false }

  before do
    allow(listener).to receive(:coordinators).and_return(coordinators)
    allow(listener).to receive(:subscription_group).and_return(subscription_group)
    allow(subscription_group).to receive(:consumer_group).and_return(consumer_group)
    allow(consumer_group).to receive(:id).and_return(consumer_group_id)

    allow(client).to receive(:assignment).and_return(topic_partition_list)
    allow(client).to receive(:pause)

    allow(topic_partition_list).to receive(:to_h).and_return({ topic_name => [partition0, partition1] })

    allow(coordinators).to receive(:find_or_create).with(topic_name, 0).and_return(coordinator0)
    allow(coordinators).to receive(:find_or_create).with(topic_name, 1).and_return(coordinator1)

    allow(coordinator0).to receive(:pause_tracker).and_return(pause_tracker0)
    allow(coordinator1).to receive(:pause_tracker).and_return(pause_tracker1)

    allow(pause_tracker0).to receive(:pause)
    allow(pause_tracker0).to receive(:paused?).and_return(false)
    allow(pause_tracker1).to receive(:pause)
    allow(pause_tracker1).to receive(:paused?).and_return(false)

    allow(Karafka::Web::Pro::Commanding::Dispatcher).to receive(:result)
    allow(Karafka::Web.config.tracking.consumers.sampler).to receive(:process_id).and_return('test-process')
  end

  describe '#call' do
    context 'when consumer group matches' do
      it 'pauses all partitions of the topic' do
        command.call

        expect(pause_tracker0).to have_received(:pause).with(duration)
        expect(pause_tracker1).to have_received(:pause).with(duration)
        expect(client).to have_received(:pause).with(topic_name, 0, nil, duration)
        expect(client).to have_received(:pause).with(topic_name, 1, nil, duration)
      end

      it 'reports applied status with affected partitions' do
        command.call

        expect(Karafka::Web::Pro::Commanding::Dispatcher).to have_received(:result) do |name, pid, payload|
          expect(name).to eq('topics.pause')
          expect(pid).to eq('test-process')
          expect(payload[:status]).to eq('applied')
          expect(payload[:partitions_affected]).to contain_exactly(0, 1)
          expect(payload[:partitions_prevented]).to be_empty
        end
      end
    end

    context 'when duration is zero' do
      let(:duration) { 0 }
      let(:forever_ms) { 10 * 365 * 24 * 60 * 60 * 1000 }

      it 'converts to forever duration' do
        command.call

        expect(pause_tracker0).to have_received(:pause).with(forever_ms)
        expect(pause_tracker1).to have_received(:pause).with(forever_ms)
        expect(client).to have_received(:pause).with(topic_name, 0, nil, forever_ms)
        expect(client).to have_received(:pause).with(topic_name, 1, nil, forever_ms)
      end
    end

    context 'when prevent_override is true and some partitions are already paused' do
      let(:prevent_override) { true }

      before do
        allow(pause_tracker0).to receive(:paused?).and_return(true)
        allow(pause_tracker1).to receive(:paused?).and_return(false)
      end

      it 'only pauses non-paused partitions' do
        command.call

        expect(pause_tracker0).not_to have_received(:pause)
        expect(pause_tracker1).to have_received(:pause).with(duration)
        expect(client).not_to have_received(:pause).with(topic_name, 0, nil, duration)
        expect(client).to have_received(:pause).with(topic_name, 1, nil, duration)
      end

      it 'reports affected and prevented partitions' do
        command.call

        expect(Karafka::Web::Pro::Commanding::Dispatcher).to have_received(:result) do |_name, _pid, payload|
          expect(payload[:status]).to eq('applied')
          expect(payload[:partitions_affected]).to contain_exactly(1)
          expect(payload[:partitions_prevented]).to contain_exactly(0)
        end
      end
    end

    context 'when prevent_override is true and all partitions are already paused' do
      let(:prevent_override) { true }

      before do
        allow(pause_tracker0).to receive(:paused?).and_return(true)
        allow(pause_tracker1).to receive(:paused?).and_return(true)
      end

      it 'does not pause any partitions' do
        command.call

        expect(pause_tracker0).not_to have_received(:pause)
        expect(pause_tracker1).not_to have_received(:pause)
        expect(client).not_to have_received(:pause)
      end

      it 'reports all partitions as prevented' do
        command.call

        expect(Karafka::Web::Pro::Commanding::Dispatcher).to have_received(:result) do |_name, _pid, payload|
          expect(payload[:status]).to eq('applied')
          expect(payload[:partitions_affected]).to be_empty
          expect(payload[:partitions_prevented]).to contain_exactly(0, 1)
        end
      end
    end

    context 'when no partitions are owned for the topic' do
      before do
        allow(topic_partition_list).to receive(:to_h).and_return({})
      end

      it 'reports applied with no affected partitions' do
        command.call

        expect(Karafka::Web::Pro::Commanding::Dispatcher).to have_received(:result) do |_name, _pid, payload|
          expect(payload[:status]).to eq('applied')
          expect(payload[:partitions_affected]).to be_empty
        end
      end
    end
  end
end
