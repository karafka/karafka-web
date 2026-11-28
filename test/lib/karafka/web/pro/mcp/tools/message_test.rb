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
  let(:arguments) { { "topic_name" => topic_name, "partition" => 0, "offset" => 0 } }
  let(:topic_name) { create_topic }
  let(:structured) { result.fetch(:structuredContent) }
  let(:text) { result.dig(:content, 0, :text) }
  let(:policy) { Karafka::Web.config.ui.policies.messages }

  it { assert(described_class.messages?) }

  context "when messages tools are disabled" do
    it { refute(described_class.available?) }
  end

  context "when messages tools are enabled" do
    before { Karafka::Web.config.mcp.messages.active = true }

    after { Karafka::Web.config.mcp.messages.active = false }

    it { assert(described_class.available?) }
  end

  context "when message exists" do
    before { produce(topic_name, { "user" => "jane" }.to_json, key: "k1", headers: { "h" => "v" }) }

    it "returns its key, headers and payload" do
      refute(result[:isError])
      assert_equal("k1", structured[:key])
      assert_equal({ "h" => "v" }, structured[:headers])
      assert_equal({ "user" => "jane" }, structured[:payload])
      assert_empty(structured[:filtered_fields])
      assert_empty(structured[:truncated_fields])
      assert_equal(%w[key headers payload], structured[:untrusted_fields])
      assert_includes(structured[:note], "untrusted")
      assert_equal(JSON.parse(structured.to_json), JSON.parse(text))
    end
  end

  context "when policy hides key, headers and payload" do
    before do
      policy.stubs(:key?).returns(false)
      policy.stubs(:headers?).returns(false)
      policy.stubs(:payload?).returns(false)
      produce(topic_name, { "user" => "jane" }.to_json, key: "secret-key", headers: { "h" => "secret" })
    end

    it "filters them out" do
      refute(result[:isError])
      assert_equal(%w[key headers payload], structured[:filtered_fields])
      assert_nil(structured[:key])
      assert_nil(structured[:headers])
      assert_nil(structured[:payload])
      refute_includes(text, "secret")
      refute_includes(text, "jane")
    end
  end

  context "when payload is encrypted" do
    before { produce(topic_name, { "user" => "jane" }.to_json, headers: { "encryption" => "1" }) }

    it "filters the payload by the default policy" do
      assert_equal(%w[payload], structured[:filtered_fields])
      refute_includes(text, "jane")
    end
  end

  context "when payload cannot be deserialized" do
    before { produce(topic_name, "{") }

    it do
      refute(result[:isError])
      assert_equal(%w[payload], structured[:failed_fields])
      assert_nil(structured[:payload])
    end
  end

  context "when payload is over the size cap" do
    before { produce(topic_name, { "data" => "a" * 20_000 }.to_json) }

    it "cuts its JSON" do
      assert_equal(%w[payload], structured[:truncated_fields])
      assert_equal(10_240, structured[:payload].bytesize)
    end
  end

  context "when offset is a transaction marker" do
    let(:arguments) { { "topic_name" => topic_name, "partition" => 0, "offset" => 1 } }

    before { produce(topic_name, "{}", type: :transactional) }

    it do
      assert(result[:isError])
      assert_includes(text, "is a transaction marker")
    end
  end

  context "when offset is beyond the data" do
    let(:arguments) { { "topic_name" => topic_name, "partition" => 0, "offset" => 100 } }

    before { produce(topic_name, "{}") }

    it do
      assert(result[:isError])
      assert_includes(text, "its offsets are 0 to 0")
    end
  end

  context "when topic does not exist" do
    let(:topic_name) { generate_topic_name }

    it do
      assert(result[:isError])
      assert_includes(text, "does not exist")
    end
  end

  context "when topic is internal and the Web UI hides internal topics" do
    let(:topic_name) { "__consumer_offsets" }

    before { Karafka::Web.config.ui.visibility.stubs(:internal_topics).returns(false) }

    it { assert_includes(text, "does not exist") }
  end

  context "when arguments are missing" do
    let(:arguments) { { "topic_name" => topic_name, "partition" => 0 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end

  context "when topic name is invalid" do
    let(:arguments) { { "topic_name" => "a b", "partition" => 0, "offset" => 0 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
