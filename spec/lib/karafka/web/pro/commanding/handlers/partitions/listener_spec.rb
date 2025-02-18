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

  let(:subscription_group) do
    instance_double(Karafka::Routing::SubscriptionGroup, id: subscription_group_id)
  end

  let(:subscription_group_id) { SecureRandom.uuid }
  let(:client) { instance_double(Karafka::Connection::Client) }
  let(:command) { instance_double(Karafka::Web::Pro::Commanding::Request) }

  before do
    allow(Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker)
      .to receive(:instance)
      .and_return(tracker)

    allow(Karafka::Web::Pro::Commanding::Handlers::Partitions::Executor)
      .to receive(:new)
      .and_return(executor)
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

    it 'executes commands for the subscription group' do
      listener.on_connection_listener_fetch_loop(event)

      expect(tracker).to have_received(:each_for).with(subscription_group_id)
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
  end

  describe '#on_rebalance_partitions_assigned' do
    let(:event) do
      {
        subscription_group_id: subscription_group_id
      }
    end

    before do
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects all pending commands' do
      listener.on_rebalance_partitions_assigned(event)

      expect(tracker).to have_received(:each_for).with(subscription_group_id)
      expect(executor).to have_received(:reject).with(command)
    end

    context 'when no commands exist' do
      before do
        allow(tracker).to receive(:each_for)
      end

      it 'does not reject anything' do
        listener.on_rebalance_partitions_assigned(event)
        expect(executor).not_to have_received(:reject)
      end
    end
  end

  describe '#on_rebalance_partitions_revoked' do
    let(:event) do
      {
        subscription_group_id: subscription_group_id
      }
    end

    before do
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects all pending commands' do
      listener.on_rebalance_partitions_revoked(event)

      expect(tracker).to have_received(:each_for).with(subscription_group_id)
      expect(executor).to have_received(:reject).with(command)
    end

    it 'behaves same as on_rebalance_partitions_assigned' do
      assigned_result = listener.on_rebalance_partitions_assigned(event)
      revoked_result = listener.on_rebalance_partitions_revoked(event)

      expect(revoked_result).to eq(assigned_result)
    end

    context 'when no commands exist' do
      before do
        allow(tracker).to receive(:each_for)
      end

      it 'does not reject anything' do
        listener.on_rebalance_partitions_revoked(event)
        expect(executor).not_to have_received(:reject)
      end
    end
  end
end
