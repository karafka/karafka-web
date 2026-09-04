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
  # Baseline valid normalized data; individual tests override via merge
  def data(**overrides)
    {
      payload: "",
      payload_file: nil,
      key: "",
      partition: "",
      headers: "",
      payload_format: "json"
    }.merge(overrides)
  end

  describe ".call" do
    it "builds a minimal message with just topic and payload" do
      message = described_class.call("t", data(payload: '{"a":1}', payload_format: "json"))

      assert_equal({ topic: "t", payload: '{"a":1}' }, message)
    end

    it "includes key, partition and headers when present" do
      message = described_class.call(
        "t",
        data(payload: "x", payload_format: "raw", key: "k", partition: "3", headers: "h: v")
      )

      assert_equal("t", message[:topic])
      assert_equal("x", message[:payload])
      assert_equal("k", message[:key])
      assert_equal(3, message[:partition])
      assert_equal({ "h" => "v" }, message[:headers])
    end

    it "omits key/partition/headers when blank" do
      message = described_class.call("t", data(payload: "x", payload_format: "raw"))

      refute(message.key?(:key))
      refute(message.key?(:partition))
      refute(message.key?(:headers))
    end

    it "prefers the uploaded file over the textarea payload" do
      message = described_class.call(
        "t",
        data(payload: "from-text", payload_file: "from-file", payload_format: "raw")
      )

      assert_equal("from-file", message[:payload])
    end
  end

  describe ".payload" do
    it "canonicalizes JSON for the json format" do
      assert_equal('{"a":1,"b":2}', described_class.payload(data(payload: '{ "a": 1, "b": 2 }')))
    end

    it "returns the raw bytes untouched for the raw format" do
      assert_equal("  raw  ", described_class.payload(data(payload: "  raw  ", payload_format: "raw")))
    end
  end

  describe ".headers" do
    it "parses key: value lines and skips blank ones" do
      assert_equal(
        { "a" => "b", "c" => "d" },
        described_class.headers("a: b\n\nc: d\n")
      )
    end
  end

  describe ".json?" do
    it { assert(described_class.json?(data(payload: '{"a":1}', payload_format: "json"))) }
    it { refute(described_class.json?(data(payload: "{ not json", payload_format: "json"))) }
    it "is always true for the raw format" do
      assert(described_class.json?(data(payload: "not json", payload_format: "raw")))
    end
  end

  describe ".headers?" do
    it { assert(described_class.headers?("a: b\nc: d")) }
    it { assert(described_class.headers?("a: b\n\n")) }
    it { refute(described_class.headers?("a: b\nno-colon")) }
    it { refute(described_class.headers?(": no-key")) }
  end
end
