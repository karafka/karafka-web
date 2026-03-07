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
    let(:message) { stub(raw_headers: raw_headers) }

    context "when the raw headers include the phrase in a key" do
      let(:raw_headers) { { "test phrase" => "some value" } }

      it "returns true" do
        assert(matcher.call(message, phrase))
      end
    end

    context "when the raw headers include the phrase in a value as header" do
      let(:raw_headers) { { "some key" => "test phrase" } }

      it "returns true" do
        assert(matcher.call(message, phrase))
      end
    end

    context "when the raw headers do not include the phrase" do
      let(:raw_headers) { { "some key" => "some value" } }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end

    context "when the raw headers include the phrase in a value as array of headers" do
      let(:raw_headers) { { "some key" => ["test phrase", "xda"] } }

      it "returns true" do
        assert(matcher.call(message, phrase))
      end
    end

    context "when the raw headers do not include the phrase as array of headers" do
      let(:raw_headers) { { "some key" => ["some value", "xda"] } }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end

    context "when there is an encoding compatibility error in a key" do
      let(:raw_headers) { { "test phrase".encode("ASCII-8BIT") => "some value" } }
      let(:phrase) { "test phrase-ó".encode("UTF-8") }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end

    context "when there is an encoding compatibility error in a value" do
      let(:raw_headers) { { "some key" => "test phrase".encode("ASCII-8BIT") } }
      let(:phrase) { "test phrase-ó".encode("UTF-8") }

      it "returns false" do
        refute(matcher.call(message, phrase))
      end
    end
  end

  describe ".name" do
    it "returns the correct name for the matcher" do
      assert_equal("Raw header includes", described_class.name)
    end
  end
end
