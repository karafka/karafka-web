# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:tracker) { instance_double(Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker) }
  let(:executor) { instance_double(Karafka::Web::Pro::Commanding::Handlers::Partitions::Executor) }
  let(:connection_listener) do
    instance_double(
      Karafka::Connection::Listener,
      subscription_group: subscription_group
    )
  end

  let(:consumer_group) do
    instance_double(Karafka::Routing::ConsumerGroup, id: consumer_group_id)
  end

  let(:subscription_group) do
    instance_double(
      Karafka::Routing::SubscriptionGroup,
      id: subscription_group_id,
      consumer_group: consumer_group,
      topics: [routing_topic]
    )
  end

  let(:routing_topic) do
    instance_double(Karafka::Routing::Topic, name: topic_name)
  end

  let(:subscription_group_id) { SecureRandom.uuid }
  let(:consumer_group_id) { 'test_consumer_group' }
  let(:topic_name) { 'test_topic' }
  let(:partition_id) { 0 }

  let(:client) { instance_double(Karafka::Connection::Client) }
  let(:command) { instance_double(Karafka::Web::Pro::Commanding::Request) }

  # Mock rdkafka partition
  let(:rdkafka_partition) do
    instance_double('Rdkafka::Consumer::Partition', partition: partition_id)
  end

  let(:assignments) do
    { topic_name => [rdkafka_partition] }
  end

  before do
    allow(Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker)
      .to receive(:instance)
      .and_return(tracker)

    allow(Karafka::Web::Pro::Commanding::Handlers::Partitions::Executor)
      .to receive(:new)
      .and_return(executor)

    allow(client).to receive(:assignment).and_return(
      instance_double('Rdkafka::Consumer::TopicPartitionList', to_h: assignments)
    )
  end

  describe '#on_connection_listener_fetch_loop' do
    let(:event) do
      {
        caller: connection_listener,
        client: client
      }
    end

    before do
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:call)
    end

    it 'executes commands for each assigned partition' do
      listener.on_connection_listener_fetch_loop(event)

      expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition_id)
      expect(executor).to have_received(:call).with(connection_listener, client, command)
    end

    context 'when no commands exist' do
      before do
        allow(tracker).to receive(:each_for)
      end

      it 'does not execute anything' do
        listener.on_connection_listener_fetch_loop(event)
        expect(executor).not_to have_received(:call)
      end
    end

    context 'with multiple partitions assigned' do
      let(:partition2_id) { 1 }
      let(:rdkafka_partition2) do
        instance_double('Rdkafka::Consumer::Partition', partition: partition2_id)
      end

      let(:assignments) do
        { topic_name => [rdkafka_partition, rdkafka_partition2] }
      end

      it 'iterates over all partitions' do
        listener.on_connection_listener_fetch_loop(event)

        expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition_id)
        expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition2_id)
      end
    end
  end

  describe '#on_rebalance_partitions_assigned' do
    let(:event) do
      {
        subscription_group: subscription_group
      }
    end

    before do
      allow(tracker).to receive(:partition_ids_for).and_return([partition_id])
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'queries partition_ids_for to get partitions with pending commands' do
      listener.on_rebalance_partitions_assigned(event)

      expect(tracker).to have_received(:partition_ids_for).with(consumer_group_id, topic_name)
    end

    it 'rejects pending commands only for partitions returned by partition_ids_for' do
      listener.on_rebalance_partitions_assigned(event)

      expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition_id)
      expect(executor).to have_received(:reject).with(command)
    end

    context 'when multiple partitions have pending commands' do
      let(:partition_id2) { 5 }

      before do
        allow(tracker).to receive(:partition_ids_for).and_return([partition_id, partition_id2])
      end

      it 'iterates only over partitions with commands' do
        listener.on_rebalance_partitions_assigned(event)

        expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition_id)
        expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition_id2)
        expect(tracker).to have_received(:each_for).twice
      end
    end

    context 'when no partitions have pending commands' do
      before do
        allow(tracker).to receive(:partition_ids_for).and_return([])
      end

      it 'does not call each_for' do
        listener.on_rebalance_partitions_assigned(event)

        expect(tracker).not_to have_received(:each_for)
        expect(executor).not_to have_received(:reject)
      end
    end
  end

  describe '#on_rebalance_partitions_revoked' do
    let(:event) do
      {
        subscription_group: subscription_group
      }
    end

    before do
      allow(tracker).to receive(:partition_ids_for).and_return([partition_id])
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects all pending commands' do
      listener.on_rebalance_partitions_revoked(event)

      expect(tracker).to have_received(:partition_ids_for).with(consumer_group_id, topic_name)
      expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name, partition_id)
      expect(executor).to have_received(:reject).with(command)
    end

    it 'behaves same as on_rebalance_partitions_assigned' do
      allow(tracker).to receive(:partition_ids_for).and_return([])

      assigned_result = listener.on_rebalance_partitions_assigned(event)
      revoked_result = listener.on_rebalance_partitions_revoked(event)

      expect(revoked_result).to eq(assigned_result)
    end

    context 'when no partitions have pending commands' do
      before do
        allow(tracker).to receive(:partition_ids_for).and_return([])
      end

      it 'does not reject anything' do
        listener.on_rebalance_partitions_revoked(event)

        expect(tracker).not_to have_received(:each_for)
        expect(executor).not_to have_received(:reject)
      end
    end
  end
end
