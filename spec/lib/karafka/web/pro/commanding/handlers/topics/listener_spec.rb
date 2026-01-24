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
  subject(:topic_listener) { described_class.new }

  let(:tracker) { Karafka::Web::Pro::Commanding::Handlers::Topics::Tracker.instance }
  let(:executor) { instance_double(Karafka::Web::Pro::Commanding::Handlers::Topics::Executor) }
  let(:consumer_group_id) { SecureRandom.uuid }
  let(:topic_name) { 'test_topic' }
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
    let(:subscription_group) { instance_double(Karafka::Routing::SubscriptionGroup) }
    let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup, id: consumer_group_id) }
    let(:topic) { instance_double(Karafka::Routing::Topic, name: topic_name) }
    let(:event) { { caller: listener, client: client } }

    before do
      allow(listener).to receive(:subscription_group).and_return(subscription_group)
      allow(subscription_group).to receive_messages(consumer_group: consumer_group, topics: [topic])
      allow(tracker).to receive(:each_for).with(consumer_group_id, topic_name).and_yield(command)
      allow(executor).to receive(:call)
    end

    it 'executes queued commands for each topic in the subscription group' do
      topic_listener.on_connection_listener_fetch_loop(event)

      expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name)
      expect(executor).to have_received(:call).with(listener, client, command)
    end

    context 'when multiple topics exist in subscription group' do
      let(:topic2) { instance_double(Karafka::Routing::Topic, name: 'test_topic2') }
      let(:command2) { instance_double(Karafka::Web::Pro::Commanding::Request) }

      before do
        allow(subscription_group)
          .to receive(:topics)
          .and_return([topic, topic2])

        allow(tracker)
          .to receive(:each_for)
          .with(consumer_group_id, 'test_topic2')
          .and_yield(command2)
      end

      it 'checks for commands on all topics' do
        topic_listener.on_connection_listener_fetch_loop(event)

        expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name)
        expect(tracker).to have_received(:each_for).with(consumer_group_id, 'test_topic2')
        expect(executor).to have_received(:call).with(listener, client, command)
        expect(executor).to have_received(:call).with(listener, client, command2)
      end
    end
  end

  describe '#on_rebalance_partitions_assigned' do
    let(:subscription_group) { instance_double(Karafka::Routing::SubscriptionGroup) }
    let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup, id: consumer_group_id) }
    let(:topic) { instance_double(Karafka::Routing::Topic, name: topic_name) }
    let(:event) { { subscription_group: subscription_group } }

    before do
      allow(subscription_group).to receive_messages(consumer_group: consumer_group, topics: [topic])
      allow(tracker).to receive(:each_for).with(consumer_group_id, topic_name).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects pending commands due to rebalance' do
      topic_listener.on_rebalance_partitions_assigned(event)

      expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name)
      expect(executor).to have_received(:reject).with(command)
    end
  end

  describe '#on_rebalance_partitions_revoked' do
    let(:subscription_group) { instance_double(Karafka::Routing::SubscriptionGroup) }
    let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup, id: consumer_group_id) }
    let(:topic) { instance_double(Karafka::Routing::Topic, name: topic_name) }
    let(:event) { { subscription_group: subscription_group } }

    before do
      allow(subscription_group).to receive_messages(consumer_group: consumer_group, topics: [topic])
      allow(tracker).to receive(:each_for).with(consumer_group_id, topic_name).and_yield(command)
      allow(executor).to receive(:reject)
    end

    it 'rejects pending commands due to revocation' do
      topic_listener.on_rebalance_partitions_revoked(event)

      expect(tracker).to have_received(:each_for).with(consumer_group_id, topic_name)
      expect(executor).to have_received(:reject).with(command)
    end
  end
end
