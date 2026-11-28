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
  let(:arguments) { { "topic_name" => topic_name, "partition" => 0 } }
  let(:topic_name) { create_topic }
  let(:structured) { result.fetch(:structuredContent) }
  let(:messages) { structured.fetch(:messages) }
  let(:text) { result.dig(:content, 0, :text) }
  let(:per_page) { Karafka::Web.config.ui.per_page }

  it { assert(described_class.messages?) }

  context "when messages tools are disabled" do
    it { refute(described_class.available?) }
  end

  context "when partition is empty" do
    it do
      refute(result[:isError])
      assert_empty(messages)
      assert_nil(structured[:older_page_offset])
      assert_nil(structured[:newer_page_offset])
    end
  end

  context "when there are more messages than one page" do
    before { produce_many(topic_name, Array.new(per_page + 5) { |i| i.to_s }, key: "k") }

    it "returns the newest page, newest first, with keys" do
      refute(result[:isError])
      assert_equal(per_page, messages.size)
      assert_equal(per_page + 4, messages.first[:offset])
      assert_equal(5, messages.last[:offset])
      assert_equal("k", messages.first[:key])
      assert_equal(0, structured[:older_page_offset])
      assert_nil(structured[:newer_page_offset])
      assert_equal(%w[messages.key], structured[:untrusted_fields])
      refute(messages.first.key?(:payload))
      assert_equal(JSON.parse(structured.to_json), JSON.parse(text))
    end

    context "when asking for the older page" do
      let(:arguments) { { "topic_name" => topic_name, "partition" => 0, "offset" => 0 } }

      it do
        assert_equal(per_page, messages.size)
        assert_equal(per_page - 1, messages.first[:offset])
        assert_equal(0, messages.last[:offset])
        assert_nil(structured[:older_page_offset])
        assert_equal(5, structured[:newer_page_offset])
      end
    end
  end

  context "when policy hides the keys" do
    before do
      Karafka::Web.config.ui.policies.messages.stubs(:key?).returns(false)
      produce(topic_name, "1", key: "secret-key")
    end

    it do
      assert_nil(messages.first[:key])
      assert_equal(%w[key], messages.first[:filtered_fields])
      refute_includes(text, "secret-key")
    end
  end

  context "when an offset holds a transaction marker" do
    before { produce(topic_name, "1", type: :transactional) }

    it { assert_equal({ offset: 1, no_data: true }, messages.first) }
  end

  context "when topic does not exist" do
    let(:topic_name) { generate_topic_name }

    it do
      assert(result[:isError])
      assert_includes(text, "does not exist")
    end
  end

  context "when partition does not exist" do
    let(:arguments) { { "topic_name" => topic_name, "partition" => 10 } }

    it do
      assert(result[:isError])
      assert_includes(text, "does not exist: the topic has 1 partition")
    end
  end

  context "when topic comes from a routing pattern" do
    before do
      name = topic_name

      draw_routes do
        pattern(/#{name}/) do
          active(false)
          deserializers(key: ->(_metadata) { "pattern-key" })
        end
      end

      produce(topic_name, "1", key: "k")
    end

    it { assert_equal("pattern-key", messages.first[:key]) }
  end

  context "when offset is negative" do
    let(:arguments) { { "topic_name" => topic_name, "partition" => 0, "offset" => -1 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end

  context "when partition is missing" do
    let(:arguments) { { "topic_name" => topic_name } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
