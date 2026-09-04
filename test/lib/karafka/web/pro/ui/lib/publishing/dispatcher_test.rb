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
  let(:topic) { create_topic }

  it "produces the given message and returns a delivery report" do
    payload = rand.to_s

    delivery = described_class.new(topic: topic, payload: payload).call

    assert_equal(topic, delivery.topic)
    assert_equal(payload, wait_for_message(topic, 0, 0).raw_payload)
  end

  it "produces with acks so the delivery report carries a real offset" do
    # Warm the topic/leader first; the very first produce to a brand-new topic can return an
    # invalid offset regardless of acks. With acks: 0 every report would be invalid instead.
    described_class.new(topic: topic, payload: "warmup").call

    delivery = described_class.new(topic: topic, payload: rand.to_s).call

    assert_operator(delivery.offset, :>=, 0)
  end

  describe "producer resolution" do
    let(:built_message) { { topic: "t", payload: "p" } }

    it "publishes through the acked variant when the web producer provides one" do
      acked = stub
      web_producer = stub
      web_producer.stubs(:respond_to?).with(:acked).returns(true)
      web_producer.stubs(:acked).returns(acked)
      Karafka::Web.stubs(:producer).returns(web_producer)

      acked.expects(:produce_sync).with(built_message).returns(:report)

      assert_equal(:report, described_class.new(built_message).call)
    end

    it "falls back to the configured producer when it has no acked variant" do
      web_producer = stub
      web_producer.stubs(:respond_to?).with(:acked).returns(false)
      Karafka::Web.stubs(:producer).returns(web_producer)

      web_producer.expects(:produce_sync).with(built_message).returns(:report)

      assert_equal(:report, described_class.new(built_message).call)
    end
  end
end
