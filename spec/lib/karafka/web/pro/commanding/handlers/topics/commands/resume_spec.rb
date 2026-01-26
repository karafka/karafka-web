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
  subject(:command) { described_class.new(listener, client, request) }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }

  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      name: "topics.resume",
      topic: topic_name,
      consumer_group_id: consumer_group_id,
      reset_attempts: reset_attempts
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

  let(:topic_name) { "test_topic" }
  let(:consumer_group_id) { "test_consumer_group" }
  let(:reset_attempts) { false }

  before do
    allow(listener)
      .to receive_messages(coordinators: coordinators, subscription_group: subscription_group)

    allow(subscription_group)
      .to receive(:consumer_group)
      .and_return(consumer_group)

    allow(consumer_group)
      .to receive(:id)
      .and_return(consumer_group_id)

    allow(client)
      .to receive(:assignment)
      .and_return(topic_partition_list)

    allow(topic_partition_list)
      .to receive(:to_h)
      .and_return({ topic_name => [partition0, partition1] })

    allow(coordinators)
      .to receive(:find_or_create)
      .with(topic_name, 0).and_return(coordinator0)
    allow(coordinators)
      .to receive(:find_or_create)
      .with(topic_name, 1).and_return(coordinator1)

    allow(coordinator0)
      .to receive(:pause_tracker)
      .and_return(pause_tracker0)
    allow(coordinator1)
      .to receive(:pause_tracker)
      .and_return(pause_tracker1)

    allow(pause_tracker0)
      .to receive_messages(expire: nil, reset: nil)
    allow(pause_tracker1)
      .to receive_messages(expire: nil, reset: nil)

    allow(Karafka::Web::Pro::Commanding::Dispatcher)
      .to receive(:result)

    allow(Karafka::Web.config.tracking.consumers.sampler)
      .to receive(:process_id)
      .and_return("test-process")
  end

  describe "#call" do
    context "when consumer group matches" do
      it "expires pause on all partitions of the topic" do
        command.call

        expect(pause_tracker0).to have_received(:expire)
        expect(pause_tracker1).to have_received(:expire)
      end

      it "reports applied status with affected partitions" do
        command.call

        expect(Karafka::Web::Pro::Commanding::Dispatcher)
          .to have_received(:result) do |name, pid, payload|
            expect(name).to eq("topics.resume")
            expect(pid).to eq("test-process")
            expect(payload[:status]).to eq("applied")
            expect(payload[:partitions_affected]).to contain_exactly(0, 1)
          end
      end

      context "when reset_attempts is false" do
        let(:reset_attempts) { false }

        it "does not reset the pause tracker attempts" do
          command.call

          expect(pause_tracker0).not_to have_received(:reset)
          expect(pause_tracker1).not_to have_received(:reset)
        end
      end

      context "when reset_attempts is true" do
        let(:reset_attempts) { true }

        it "resets the pause tracker attempts" do
          command.call

          expect(pause_tracker0).to have_received(:reset)
          expect(pause_tracker1).to have_received(:reset)
        end
      end
    end

    context "when no partitions are owned for the topic" do
      before do
        allow(topic_partition_list).to receive(:to_h).and_return({})
      end

      it "reports applied with no affected partitions" do
        command.call

        expect(Karafka::Web::Pro::Commanding::Dispatcher)
          .to have_received(:result) do |_name, _pid, payload|
            expect(payload[:status]).to eq("applied")
            expect(payload[:partitions_affected]).to be_empty
          end
      end
    end
  end
end
