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
  def built_message(overrides = {})
    { topic: "t", payload: "hello" }.merge(overrides)
  end

  context "when the topic is not in the routing" do
    before { ::Karafka::Routing::Router.stubs(:find_by).with(name: "t").returns(nil) }

    it "skips validation" do
      assert_nil(described_class.call(built_message(payload: "{ not json")))
    end
  end

  context "when the topic is routed with a JSON deserializer" do
    let(:topic) do
      stub(deserializers?: true, deserializers: stub(payload: Karafka::Deserializers::Payload.new))
    end

    before { ::Karafka::Routing::Router.stubs(:find_by).with(name: "t").returns(topic) }

    it "returns nil for a payload the deserializer can read" do
      assert_nil(described_class.call(built_message(payload: '{"a":1}')))
    end

    it "returns an error for a payload the deserializer cannot read" do
      refute_nil(described_class.call(built_message(payload: "{ not json")))
    end

    it "skips a tombstone (nil payload)" do
      assert_nil(described_class.call(built_message(payload: nil)))
    end
  end

  context "when the routed topic has no active deserializer" do
    let(:topic) { stub(deserializers?: false) }

    before { ::Karafka::Routing::Router.stubs(:find_by).with(name: "t").returns(topic) }

    it "skips validation" do
      assert_nil(described_class.call(built_message(payload: "{ not json")))
    end
  end
end
