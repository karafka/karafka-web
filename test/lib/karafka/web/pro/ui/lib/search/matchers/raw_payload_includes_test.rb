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
  let(:matcher) { described_class.new }

  describe ".active?" do
    it { assert(described_class.active?(rand.to_s)) }
  end

  describe "#call" do
    let(:phrase) { "test phrase" }
    let(:headers) { {} }

    let(:message) do
      instance_double(
        Karafka::Messages::Message,
        raw_payload: raw_payload,
        raw_headers: headers
      )
    end

    context "when the raw payload includes the phrase" do
      let(:raw_payload) { "This is a test phrase in the message." }

      it "returns true" do
        assert(matcher.call(message, phrase))
      end
    end

    context "when the raw payload is nil (tombstone)" do
      let(:raw_payload) { nil }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end

    context "when the raw payload does not include the phrase" do
      let(:raw_payload) { "This message does not contain the search term." }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end

    context "when there is an encoding compatibility error" do
      let(:raw_payload) { "This is a test phrase in the message.".encode("ASCII-8BIT") }
      let(:phrase) { "test phrase-ó".encode("UTF-8") }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end

    context "when message has a zlib header but payload is not zlibed" do
      let(:raw_payload) { "This is a test phrase in the message." }
      let(:headers) { { "zlib" => "true" } }

      it "returns true on match" do
        assert(matcher.call(message, phrase))
      end
    end

    context "when message has a zlib header and payload is zlibed" do
      let(:raw_payload) { Zlib.deflate("This is a test phrase in the message.") }
      let(:headers) { { "zlib" => "true" } }

      it "returns true on match" do
        assert(matcher.call(message, phrase))
      end
    end

    context "when message has no zlib header and payload is zlibed" do
      let(:raw_payload) { Zlib.deflate("This is a test phrase in the message.") }

      it "returns false on match" do
        refute(matcher.call(message, phrase))
      end
    end
  end

  describe ".name" do
    it "returns the correct name for the matcher" do
      assert_equal("Raw payload includes", described_class.name)
    end
  end
end
