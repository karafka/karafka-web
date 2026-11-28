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
  let(:result) { described_class.new(arguments).call }
  let(:arguments) { {} }
  let(:structured) { result.fetch(:structuredContent) }
  let(:routed_topic) { generate_topic_name }
  let(:routed_group) { "it-routing-#{SecureRandom.uuid}" }
  let(:group) { structured.fetch(:consumer_groups).find { |cg| cg[:id] == routed_group } }

  context "when the routing has a consumer group" do
    before do
      group_id = routed_group
      topic_name = routed_topic
      draw_routes do
        consumer_group group_id do
          topic topic_name do
            consumer Karafka::BaseConsumer
          end

          topic "#{topic_name}-inactive" do
            active false
          end
        end
      end
    end

    it "lists its topics as on the Web UI Routing page" do
      refute(result[:isError])

      topic = group[:topics].find { |details| details[:name] == routed_topic }
      inactive = group[:topics].find { |details| details[:name] == "#{routed_topic}-inactive" }

      assert_equal(Karafka::Routing::Router.find_by(name: routed_topic).id, topic[:id])
      assert_equal(:regular, topic[:type])
      assert_nil(topic[:multiplexing])
      refute(topic[:assigned])
      assert(topic[:active])
      refute(inactive[:active])
      assert_equal(Karafka::Routing::Router.find_by(name: routed_topic).subscription_group.id, topic[:subscription_group])
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end
  end

  context "when a subscription group is multiplexed" do
    before do
      group_id = routed_group
      topic_name = routed_topic
      draw_routes do
        consumer_group group_id do
          subscription_group do
            multiplexing(min: 1, max: 2)

            topic topic_name do
              consumer Karafka::BaseConsumer
            end
          end
        end
      end
    end

    it "returns its multiplexing" do
      assert_equal({ min: 1, max: 2 }, group[:topics].first[:multiplexing])
    end
  end

  context "when an active process reports the topic" do
    let(:routed_group) { "example_app6_app" }
    let(:routed_topic) { "default" }

    before do
      draw_routes do
        consumer_group "example_app6_app" do
          topic "default" do
            consumer Karafka::BaseConsumer
          end
        end
      end
    end

    it "marks it as assigned" do
      assert(group[:topics].find { |details| details[:name] == routed_topic }[:assigned])
    end
  end

  context "when the routing has a share group next to a consumer group" do
    let(:share_group_id) { "it-share-#{SecureRandom.uuid}" }

    before do
      group_id = routed_group
      topic_name = routed_topic
      share_id = share_group_id
      draw_routes do
        consumer_group group_id do
          topic topic_name do
            consumer Karafka::BaseConsumer
          end
        end

        share_group share_id do
          topic "#{topic_name}-share" do
            consumer Karafka::ShareConsumer
          end
        end
      end
    end

    it "lists only the consumer groups" do
      refute(result[:isError])
      assert_equal([routed_topic], group[:topics].map { |details| details[:name] })
      refute_includes(structured.fetch(:consumer_groups).map { |cg| cg[:id] }, share_group_id)
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "topic_id" => "test" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
