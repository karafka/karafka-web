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
  let(:matcher) { described_class.new(message) }

  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      payload: { matchers: matchers }
    )
  end

  let(:matchers) { { consumer_group_id: "my_consumer_group" } }

  let(:consumer_group) do
    instance_double(Karafka::Routing::ConsumerGroup, id: "my_consumer_group")
  end

  let(:topic) do
    instance_double(Karafka::Routing::Topic, name: "my_topic", consumer_group: consumer_group)
  end

  let(:assignments) { { topic => [0, 1, 2] } }

  before do
    allow(Karafka::App).to receive(:assignments).and_return(assignments)
  end

  describe "#apply?" do
    context "when consumer_group_id is not specified in matchers" do
      let(:matchers) { {} }

      it { refute_predicate(matcher, :apply?) }
    end

    context "when consumer_group_id is specified in matchers" do
      let(:matchers) { { consumer_group_id: "my_consumer_group" } }

      it { assert_predicate(matcher, :apply?) }
    end
  end

  describe "#matches?" do
    context "when consumer_group_id matches an assigned topic consumer group" do
      let(:matchers) { { consumer_group_id: "my_consumer_group" } }

      it { assert_predicate(matcher, :matches?) }
    end

    context "when consumer_group_id does not match any assigned consumer group" do
      let(:matchers) { { consumer_group_id: "other_consumer_group" } }

      it { refute_predicate(matcher, :matches?) }
    end

    context "when there are no assignments" do
      let(:assignments) { {} }
      let(:matchers) { { consumer_group_id: "my_consumer_group" } }

      it { refute_predicate(matcher, :matches?) }
    end

    context "when there are multiple assignments from different consumer groups" do
      let(:consumer_group2) do
        instance_double(Karafka::Routing::ConsumerGroup, id: "second_consumer_group")
      end

      let(:topic2) do
        instance_double(Karafka::Routing::Topic, name: "topic2", consumer_group: consumer_group2)
      end

      let(:assignments) { { topic => [0, 1], topic2 => [0] } }

      context "when matching first consumer group" do
        let(:matchers) { { consumer_group_id: "my_consumer_group" } }

        it { assert_predicate(matcher, :matches?) }
      end

      context "when matching second consumer group" do
        let(:matchers) { { consumer_group_id: "second_consumer_group" } }

        it { assert_predicate(matcher, :matches?) }
      end

      context "when matching neither consumer group" do
        let(:matchers) { { consumer_group_id: "third_consumer_group" } }

        it { refute_predicate(matcher, :matches?) }
      end
    end
  end
end
