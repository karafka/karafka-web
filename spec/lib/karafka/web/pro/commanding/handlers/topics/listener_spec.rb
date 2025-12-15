# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:topic_listener) { described_class.new }

  let(:tracker) { Karafka::Web::Pro::Commanding::Handlers::Topics::Tracker.instance }
  let(:executor) { instance_double(Karafka::Web::Pro::Commanding::Handlers::Topics::Executor) }
  let(:subscription_group_id) { SecureRandom.uuid }
  let(:command) { instance_double(Karafka::Web::Pro::Commanding::Request) }

  before do
    allow(Karafka::Web::Pro::Commanding::Handlers::Topics::Tracker)
      .to receive(:instance)
      .and_return(tracker)

    allow(Karafka::Web::Pro::Commanding::Handlers::Topics::Executor)
      .to receive(:new)
      .and_return(executor)
  end

  describe '#on_connection_listener_fetch_loop' do
    let(:listener) { instance_double(Karafka::Connection::Listener) }
    let(:client) { instance_double(Karafka::Connection::Client) }
    let(:subscription_group) { instance_double('SubscriptionGroup', id: subscription_group_id) }
    let(:event) { { caller: listener, client: client } }

    before do
      allow(listener).to receive(:subscription_group).and_return(subscription_group)
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:call)
    end

    it 'executes queued commands for the subscription group' do
      topic_listener.on_connection_listener_fetch_loop(event)

      expect(executor).to have_received(:call).with(listener, client, command)
    end
  end

  describe '#on_rebalance_partitions_assigned' do
    let(:event) { { subscription_group_id: subscription_group_id } }

    before do
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects pending commands due to rebalance' do
      topic_listener.on_rebalance_partitions_assigned(event)

      expect(executor).to have_received(:reject).with(command)
    end
  end

  describe '#on_rebalance_partitions_revoked' do
    let(:event) { { subscription_group_id: subscription_group_id } }

    before do
      allow(tracker).to receive(:each_for).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects pending commands due to revocation' do
      topic_listener.on_rebalance_partitions_revoked(event)

      expect(executor).to have_received(:reject).with(command)
    end
  end
end
