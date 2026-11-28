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
  let(:routed_topic) { generate_topic_name }
  let(:routed_group) { "it-routing-#{SecureRandom.uuid}" }
  let(:share_topic) { "#{routed_topic}-share" }

  before do
    group_id = routed_group
    topic_name = routed_topic
    share_name = share_topic

    draw_routes do
      consumer_group group_id do
        topic topic_name do
          consumer Karafka::BaseConsumer
          max_messages 7
        end
      end

      share_group "it-share-#{SecureRandom.uuid}" do
        topic share_name do
          consumer Karafka::ShareConsumer
        end
      end
    end
  end

  describe "#consumer_groups" do
    it "skips the share groups" do
      assert(described_class.consumer_groups.all?(&:consumer_group?))
      assert_includes(described_class.consumer_groups.map(&:id), routed_group)
    end
  end

  describe "#find_topic" do
    let(:route) { Karafka::Routing::Router.find_by(name: routed_topic) }
    let(:share_route) do
      Karafka::App.routes.share_groups.flat_map { |group| group.topics.to_a }.find { |topic| topic.name == share_topic }
    end

    it { assert_same(route, described_class.find_topic(route.id)) }
    it { assert_nil(described_class.find_topic(share_route.id)) }
    it { assert_nil(described_class.find_topic("na")) }
  end

  describe "#assigned_topics" do
    it "lists the topics of the active processes per consumer group" do
      assert_includes(described_class.assigned_topics["example_app6_app"], "default")
      assert_empty(described_class.assigned_topics[routed_group])
    end

    context "when there is no consumers state" do
      before { Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns(false) }

      it { assert_empty(described_class.assigned_topics) }
    end
  end

  describe "#settings" do
    let(:rows) { described_class.settings(Karafka::Routing::Router.find_by(name: routed_topic)) }
    let(:settings) { rows.to_h { |row| [row[:name], row[:value]] } }

    it "flattens the topic, kafka and multiplexing settings" do
      assert_equal(7, settings["max_messages"])
      assert(settings.key?("kafka.bootstrap.servers"))
      assert(settings.key?("multiplexing.max"))
    end
  end
end
