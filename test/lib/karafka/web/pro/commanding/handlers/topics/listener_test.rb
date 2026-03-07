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

describe_current do
  let(:topic_listener) { described_class.new }

  let(:tracker) { Karafka::Web::Pro::Commanding::Handlers::Topics::Tracker.instance }
  let(:executor) { stub }
  let(:consumer_group_id) { SecureRandom.uuid }
  let(:topic_name) { "test_topic" }
  let(:command) { stub }

  before do
    Karafka::Web::Pro::Commanding::Handlers::Topics::Tracker.stubs(:instance).returns(tracker)

    Karafka::Web::Pro::Commanding::Handlers::Topics::Executor.stubs(:new).returns(executor)
  end

  describe "#on_connection_listener_fetch_loop" do
    let(:listener) { stub }
    let(:client) { stub }
    let(:subscription_group) { stub }
    let(:consumer_group) { stub(id: consumer_group_id) }
    let(:topic) { stub(name: topic_name) }
    let(:event) { { caller: listener, client: client } }

    before do
      listener.stubs(:subscription_group).returns(subscription_group)
      subscription_group.stubs(:consumer_group).returns(consumer_group)
      subscription_group.stubs(:topics).returns([topic])
      tracker.stubs(:each_for).with(consumer_group_id, topic_name).and_yield(command)
      executor.stubs(:call)
    end

    it "executes queued commands for each topic in the subscription group" do
      tracker.expects(:each_for).with(consumer_group_id, topic_name)
      executor.expects(:call).with(listener, client, command)
      topic_listener.on_connection_listener_fetch_loop(event)
    end

    context "when multiple topics exist in subscription group" do
      let(:topic2) { stub(name: "test_topic2") }
      let(:command2) { stub }

      before do
        subscription_group.stubs(:topics).returns([topic, topic2])

        tracker.stubs(:each_for).with(consumer_group_id, "test_topic2").and_yield(command2)
      end

      it "checks for commands on all topics" do
        tracker.expects(:each_for).with(consumer_group_id, topic_name)
        tracker.expects(:each_for).with(consumer_group_id, "test_topic2")
        executor.expects(:call).with(listener, client, command)
        executor.expects(:call).with(listener, client, command2)
        topic_listener.on_connection_listener_fetch_loop(event)
      end
    end
  end

  describe "#on_rebalance_partitions_assigned" do
    let(:subscription_group) { stub }
    let(:consumer_group) { stub(id: consumer_group_id) }
    let(:topic) { stub(name: topic_name) }
    let(:event) { { subscription_group: subscription_group } }

    before do
      subscription_group.stubs(:consumer_group).returns(consumer_group)
      subscription_group.stubs(:topics).returns([topic])
      tracker.stubs(:each_for).with(consumer_group_id, topic_name).and_yield(command)
      executor.stubs(:reject)
    end

    it "rejects pending commands due to rebalance" do
      tracker.expects(:each_for).with(consumer_group_id, topic_name)
      executor.expects(:reject).with(command)
      topic_listener.on_rebalance_partitions_assigned(event)
    end
  end

  describe "#on_rebalance_partitions_revoked" do
    let(:subscription_group) { stub }
    let(:consumer_group) { stub(id: consumer_group_id) }
    let(:topic) { stub(name: topic_name) }
    let(:event) { { subscription_group: subscription_group } }

    before do
      subscription_group.stubs(:consumer_group).returns(consumer_group)
      subscription_group.stubs(:topics).returns([topic])
      tracker.stubs(:each_for).with(consumer_group_id, topic_name).and_yield(command)
      executor.stubs(:reject)
    end

    it "rejects pending commands due to revocation" do
      tracker.expects(:each_for).with(consumer_group_id, topic_name)
      executor.expects(:reject).with(command)
      topic_listener.on_rebalance_partitions_revoked(event)
    end
  end
end
