# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:command) { described_class.new(listener, client, request) }

  let(:listener) { stub }
  let(:client) { stub }

  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      name: "topics.resume",
      topic: topic_name,
      consumer_group_id: consumer_group_id,
      reset_attempts: reset_attempts
    )
  end

  let(:coordinators) { stub }
  let(:coordinator0) { stub }
  let(:coordinator1) { stub }
  let(:pause_tracker0) { stub }
  let(:pause_tracker1) { stub }
  let(:subscription_group) { stub }
  let(:consumer_group) { stub }
  let(:topic_partition_list) { { topic_name => [partition0, partition1] } }
  let(:partition0) { stub(partition: 0) }
  let(:partition1) { stub(partition: 1) }

  let(:topic_name) { "test_topic" }
  let(:consumer_group_id) { "test_consumer_group" }
  let(:reset_attempts) { false }

  before do
    listener.stubs(:coordinators).returns(coordinators)
    listener.stubs(:subscription_group).returns(subscription_group)

    subscription_group.stubs(:consumer_group).returns(consumer_group)

    consumer_group.stubs(:id).returns(consumer_group_id)

    client.stubs(:assignment).returns(topic_partition_list)

    topic_partition_list.stubs(:to_h).returns({ topic_name => [partition0, partition1] })

    coordinators.stubs(:find_or_create).with(topic_name, 0).returns(coordinator0)
    coordinators.stubs(:find_or_create).with(topic_name, 1).returns(coordinator1)

    coordinator0.stubs(:pause_tracker).returns(pause_tracker0)
    coordinator1.stubs(:pause_tracker).returns(pause_tracker1)

    pause_tracker0.stubs(:expire).returns(nil)
    pause_tracker0.stubs(:reset).returns(nil)
    pause_tracker1.stubs(:expire).returns(nil)
    pause_tracker1.stubs(:reset).returns(nil)

    Karafka::Web::Pro::Commanding::Dispatcher.stubs(:result)

    Karafka::Web.config.tracking.consumers.sampler.stubs(:process_id).returns("test-process")
  end

  describe "#call" do
    context "when consumer group matches" do
      it "expires pause on all partitions of the topic" do
        pause_tracker0.expects(:expire)
        pause_tracker1.expects(:expire)
        command.call
      end

      it "reports applied status with affected partitions" do
        captured = nil
        Karafka::Web::Pro::Commanding::Dispatcher.stubs(:result).with { |*args|
          captured = args
          true
        }

        command.call

        name, pid, payload = captured

        assert_equal("topics.resume", name)
        assert_equal("test-process", pid)
        assert_equal("applied", payload[:status])
        assert_equal([0, 1].sort, payload[:partitions_affected].sort)
      end

      context "when reset_attempts is false" do
        let(:reset_attempts) { false }

        it "does not reset the pause tracker attempts" do
          pause_tracker0.expects(:reset).never
          pause_tracker1.expects(:reset).never
          command.call
        end
      end

      context "when reset_attempts is true" do
        let(:reset_attempts) { true }

        it "resets the pause tracker attempts" do
          pause_tracker0.expects(:reset)
          pause_tracker1.expects(:reset)
          command.call
        end
      end
    end

    context "when no partitions are owned for the topic" do
      before do
        topic_partition_list.stubs(:to_h).returns({})
      end

      it "reports applied with no affected partitions" do
        captured = nil
        Karafka::Web::Pro::Commanding::Dispatcher.stubs(:result).with { |*args|
          captured = args
          true
        }

        command.call

        _name, _pid, payload = captured

        assert_equal("applied", payload[:status])
        assert_empty(payload[:partitions_affected])
      end
    end
  end
end
