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
  let(:listener) { described_class.new }

  let(:tracker) { stub }
  let(:executor) { stub }
  let(:connection_listener) do
    stub(subscription_group: subscription_group)
  end

  let(:consumer_group) do
    stub(id: consumer_group_id)
  end

  let(:subscription_group) do
    stub(id: subscription_group_id,
      consumer_group: consumer_group,
      topics: [routing_topic])
  end

  let(:routing_topic) do
    stub(name: topic_name)
  end

  let(:subscription_group_id) { SecureRandom.uuid }
  let(:consumer_group_id) { "test_consumer_group" }
  let(:topic_name) { "test_topic" }
  let(:partition_id) { 0 }

  let(:client) { stub }
  let(:command) { stub }

  let(:rdkafka_partition) do
    stub(partition: partition_id)
  end

  let(:assignments) do
    { topic_name => [rdkafka_partition] }
  end

  before do
    Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker.stubs(:instance).returns(tracker)

    Karafka::Web::Pro::Commanding::Handlers::Partitions::Executor.stubs(:new).returns(executor)

    client.stubs(:assignment).returns(stub(to_h: assignments))
  end

  describe "#on_connection_listener_fetch_loop" do
    let(:event) do
      {
        caller: connection_listener,
        client: client
      }
    end

    before do
      tracker.stubs(:each_for).yields(command)
      executor.stubs(:call)
    end

    it "executes commands for each assigned partition" do
      tracker.expects(:each_for).with(consumer_group_id, topic_name, partition_id)
      executor.expects(:call).with(connection_listener, client, command)
      listener.on_connection_listener_fetch_loop(event)
    end

    context "when no commands exist" do
      before do
        tracker.stubs(:each_for)
      end

      it "does not execute anything" do
        executor.expects(:call).never
        listener.on_connection_listener_fetch_loop(event)
      end
    end

    context "with multiple partitions assigned" do
      let(:partition2_id) { 1 }
      let(:rdkafka_partition2) do
        stub(partition: partition2_id)
      end

      let(:assignments) do
        { topic_name => [rdkafka_partition, rdkafka_partition2] }
      end

      it "iterates over all partitions" do
        tracker.expects(:each_for).with(consumer_group_id, topic_name, partition_id).yields(command)
        tracker.expects(:each_for).with(consumer_group_id, topic_name, partition2_id).yields(command)
        listener.on_connection_listener_fetch_loop(event)
      end
    end
  end

  describe "#on_rebalance_partitions_assigned" do
    let(:event) do
      {
        subscription_group: subscription_group
      }
    end

    before do
      tracker.stubs(:partition_ids_for).returns([partition_id])
      tracker.stubs(:each_for).yields(command)
      executor.stubs(:reject)
    end

    it "queries partition_ids_for to get partitions with pending commands" do
      tracker.expects(:partition_ids_for).with(consumer_group_id, topic_name)
      listener.on_rebalance_partitions_assigned(event)
    end

    it "rejects pending commands only for partitions returned by partition_ids_for" do
      tracker.expects(:each_for).with(consumer_group_id, topic_name, partition_id)
      executor.expects(:reject).with(command)
      listener.on_rebalance_partitions_assigned(event)
    end

    context "when multiple partitions have pending commands" do
      let(:partition_id2) { 5 }

      before do
        tracker.stubs(:partition_ids_for).returns([partition_id, partition_id2])
      end

      it "iterates only over partitions with commands" do
        tracker.expects(:each_for).with(consumer_group_id, topic_name, partition_id).yields(command)
        tracker.expects(:each_for).with(consumer_group_id, topic_name, partition_id2).yields(command)
        listener.on_rebalance_partitions_assigned(event)
      end
    end

    context "when no partitions have pending commands" do
      before do
        tracker.stubs(:partition_ids_for).returns([])
      end

      it "does not call each_for" do
        tracker.expects(:each_for).never
        executor.expects(:reject).never
        listener.on_rebalance_partitions_assigned(event)
      end
    end
  end

  describe "#on_rebalance_partitions_revoked" do
    let(:event) do
      {
        subscription_group: subscription_group
      }
    end

    before do
      tracker.stubs(:partition_ids_for).returns([partition_id])
      tracker.stubs(:each_for).yields(command)
      executor.stubs(:reject)
    end

    it "rejects all pending commands" do
      tracker.expects(:partition_ids_for).with(consumer_group_id, topic_name)
      tracker.expects(:each_for).with(consumer_group_id, topic_name, partition_id)
      executor.expects(:reject).with(command)
      listener.on_rebalance_partitions_revoked(event)
    end

    it "behaves same as on_rebalance_partitions_assigned" do
      tracker.stubs(:partition_ids_for).returns([])

      assigned_result = listener.on_rebalance_partitions_assigned(event)
      revoked_result = listener.on_rebalance_partitions_revoked(event)

      assert_equal(assigned_result, revoked_result)
    end

    context "when no partitions have pending commands" do
      before do
        tracker.stubs(:partition_ids_for).returns([])
      end

      it "does not reject anything" do
        tracker.expects(:each_for).never
        executor.expects(:reject).never
        listener.on_rebalance_partitions_revoked(event)
      end
    end
  end
end
