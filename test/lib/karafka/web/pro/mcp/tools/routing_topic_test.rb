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
  let(:arguments) { { "topic_id" => topic_id } }
  let(:topic_id) { Karafka::Routing::Router.find_by(name: routed_topic).id }
  let(:structured) { result.fetch(:structuredContent) }
  let(:settings) { structured.fetch(:settings).to_h { |row| [row[:name], row[:value]] } }
  let(:routed_topic) { generate_topic_name }
  let(:routed_group) { "it-routing-#{SecureRandom.uuid}" }

  before do
    group_id = routed_group
    topic_name = routed_topic
    draw_routes do
      consumer_group group_id do
        topic topic_name do
          consumer Karafka::BaseConsumer
          max_messages 7
          kafka(
            "bootstrap.servers": "127.0.0.1:9092",
            "sasl.password": "secret",
            "ssl.key.password": "secret"
          )
        end
      end
    end
  end

  context "when the route exists" do
    it "returns its settings sorted by name" do
      refute(result[:isError])
      assert_equal(topic_id, structured[:id])
      assert_equal(routed_topic, structured[:name])
      assert_equal(routed_group, structured[:consumer_group])
      assert_equal("7", settings["max_messages"])
      assert_equal("127.0.0.1:9092", settings["kafka.bootstrap.servers"])
      assert(settings.key?("multiplexing.max"))
      names = structured.fetch(:settings).map { |row| row[:name] }

      assert_equal(names.sort, names)
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end

    it "masks the sasl and ssl settings as the Web UI does" do
      assert_equal("***", settings["kafka.sasl.password"])
      assert_equal("***", settings["kafka.ssl.key.password"])
      refute_includes(result.dig(:content, 0, :text), "secret")
    end
  end

  context "when the route does not exist" do
    let(:topic_id) { "it-missing-#{SecureRandom.uuid}" }

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "No routed topic with id")
    end
  end

  context "when topic id is missing" do
    let(:arguments) { {} }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end

  context "when topic id is not a string" do
    let(:arguments) { { "topic_id" => 1 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
