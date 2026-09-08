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
  let(:source) do
    stub(
      raw_payload: "payload",
      headers: { "h" => "v" },
      key: "k",
      topic: "src",
      partition: 3,
      offset: 7
    )
  end

  def data(**overrides)
    {
      target_topic: "dst",
      target_partition: "",
      include_source_headers: false
    }.merge(overrides)
  end

  it "copies the payload, key and headers to the target topic" do
    message = described_class.call(source, data)

    assert_equal("dst", message[:topic])
    assert_equal("payload", message[:payload])
    assert_equal("k", message[:key])
    assert_equal({ "h" => "v" }, message[:headers])
    refute(message.key?(:partition))
  end

  it "sets the target partition when provided" do
    message = described_class.call(source, data(target_partition: "1"))

    assert_equal(1, message[:partition])
  end

  it "adds source-tracking headers when requested" do
    message = described_class.call(source, data(include_source_headers: true))

    assert_equal("v", message[:headers]["h"])
    assert_equal("src", message[:headers]["source_topic"])
    assert_equal("3", message[:headers]["source_partition"])
    assert_equal("7", message[:headers]["source_offset"])
  end

  it "does not mutate the source message headers" do
    original = { "h" => "v" }
    message = stub(
      raw_payload: "p", headers: original, key: nil, topic: "s", partition: 0, offset: 0
    )

    described_class.call(message, data(include_source_headers: true))

    refute(original.key?("source_topic"))
  end
end
