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
  let(:command) { described_class.new(listener, client, request) }

  let(:listener) { stub() }
  let(:client) { stub() }

  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      name: "topics.pause",
      topic: topic_name,
      consumer_group_id: consumer_group_id,
      duration: duration,
      prevent_override: prevent_override
    )
  end

  let(:coordinators) { stub() }
  let(:coordinator0) { stub() }
  let(:coordinator1) { stub() }
  let(:pause_tracker0) { stub() }
  let(:pause_tracker1) { stub() }
  let(:subscription_group) { stub() }
  let(:consumer_group) { stub() }
  let(:topic_partition_list) { { topic_name => [partition0, partition1] } }
  let(:partition0) { stub(partition: 0) }
  let(:partition1) { stub(partition: 1) }

  let(:topic_name) { "test_topic" }
  let(:consumer_group_id) { "test_consumer_group" }
  let(:duration) { 60_000 }
  let(:prevent_override) { false }

  before do
    listener.stubs(:coordinators).returns(coordinators)
    listener.stubs(:subscription_group).returns(subscription_group)

    subscription_group.stubs(:consumer_group).returns(consumer_group)

    consumer_group.stubs(:id).returns(consumer_group_id)

    client.stubs(:assignment).returns(topic_partition_list)
    client.stubs(:pause).returns(nil)

    topic_partition_list.stubs(:to_h).returns({ topic_name => [partition0, partition1] })

    coordinators.stubs(:find_or_create).with(topic_name, 0).returns(coordinator0)
    coordinators.stubs(:find_or_create).with(topic_name, 1).returns(coordinator1)

    coordinator0.stubs(:pause_tracker).returns(pause_tracker0)

    coordinator1.stubs(:pause_tracker).returns(pause_tracker1)

    pause_tracker0.stubs(:pause).returns(nil)
    pause_tracker0.stubs(:paused?).returns(false)

    pause_tracker1.stubs(:pause).returns(nil)
    pause_tracker1.stubs(:paused?).returns(false)

    Karafka::Web::Pro::Commanding::Dispatcher.stubs(:result)

    Karafka::Web.config.tracking.consumers.sampler.stubs(:process_id).returns("test-process")
  end

  describe "#call" do
    context "when consumer group matches" do
      it "pauses all partitions of the topic" do
        pause_tracker0.expects(:pause).with(duration)
        pause_tracker1.expects(:pause).with(duration)
        client.expects(:pause).with(topic_name, 0, nil, duration)
        client.expects(:pause).with(topic_name, 1, nil, duration)
        command.call

      end

      it "reports applied status with affected partitions" do
        command.call

        # TODO: have_received with block - needs manual conversion
        # Original: expect(Karafka::Web::Pro::Commanding::Dispatcher) .to have_received(:result) do |name, pid, payload|
            assert_equal("topics.pause", name)
            assert_equal("test-process", pid)
            assert_equal("applied", payload[:status])
            assert_equal([0, 1].sort, (payload[:partitions_affected]).sort)

            assert_empty(payload[:partitions_prevented])
          end
      end
    end

    context "when duration is zero" do
      let(:duration) { 0 }
      let(:forever_ms) { 10 * 365 * 24 * 60 * 60 * 1000 }

      it "converts to forever duration" do
        pause_tracker0.expects(:pause).with(forever_ms)
        pause_tracker1.expects(:pause).with(forever_ms)
        client.expects(:pause).with(topic_name, 0, nil, forever_ms)
        client.expects(:pause).with(topic_name, 1, nil, forever_ms)
        command.call

      end
    end

    context "when prevent_override is true and some partitions are already paused" do
      let(:prevent_override) { true }

      before do
        pause_tracker0.stubs(:paused?).returns(true)
        pause_tracker1.stubs(:paused?).returns(false)
      end

      it "only pauses non-paused partitions" do
        pause_tracker0.expects(:pause).never
        pause_tracker1.expects(:pause).with(duration)
        client.expects(:pause).with(topic_name, 0, nil, duration).never
        client.expects(:pause).with(topic_name, 1, nil, duration)
        command.call

      end

      it "reports affected and prevented partitions" do
        command.call

        # TODO: have_received with block - needs manual conversion
        # Original: expect(Karafka::Web::Pro::Commanding::Dispatcher) .to have_received(:result) do |_name, _pid, payload|
            assert_equal("applied", payload[:status])
            assert_equal([1].sort, (payload[:partitions_affected]).sort)
            assert_equal([0].sort, (payload[:partitions_prevented]).sort)
          end
      end
    end

    context "when prevent_override is true and all partitions are already paused" do
      let(:prevent_override) { true }

      before do
        pause_tracker0.stubs(:paused?).returns(true)
        pause_tracker1.stubs(:paused?).returns(true)
      end

      it "does not pause any partitions" do
        pause_tracker0.expects(:pause).never
        pause_tracker1.expects(:pause).never
        client.expects(:pause).never
        command.call

      end

      it "reports all partitions as prevented" do
        command.call

        # TODO: have_received with block - needs manual conversion
        # Original: expect(Karafka::Web::Pro::Commanding::Dispatcher) .to have_received(:result) do |_name, _pid, payload|
            assert_equal("applied", payload[:status])
            assert_empty(payload[:partitions_affected])
            assert_equal([0, 1].sort, (payload[:partitions_prevented]).sort)
          end
      end
    end

    context "when no partitions are owned for the topic" do
      before do
        topic_partition_list.stubs(:to_h).returns({})
      end

      it "reports applied with no affected partitions" do
        command.call

        # TODO: have_received with block - needs manual conversion
        # Original: expect(Karafka::Web::Pro::Commanding::Dispatcher) .to have_received(:result) do |_name, _pid, payload|
            assert_equal("applied", payload[:status])
            assert_empty(payload[:partitions_affected])
          end
      end
    end
  end
end
