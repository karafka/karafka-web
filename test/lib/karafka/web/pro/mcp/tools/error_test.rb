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
  let(:arguments) { { "partition" => 0, "offset" => 0 } }
  let(:structured) { result.fetch(:structuredContent) }
  let(:text) { result.dig(:content, 0, :text) }
  let(:errors_topic) { create_topic(partitions: 2) }
  let(:error_report) { Fixtures.errors_file }

  before { Karafka::Web.config.topics.errors.name = errors_topic }

  context "when report exists" do
    let(:arguments) { { "partition" => 1, "offset" => 0 } }
    let(:error_report) do
      report = JSON.parse(Fixtures.errors_file)
      report["details"]["sasl.password"] = "secret"
      report["details"]["nested"] = { "ssl.key.password" => "secret" }
      report.to_json
    end

    before { produce(errors_topic, error_report, partition: 1) }

    it "returns the full report with credentials masked" do
      refute(result[:isError])

      error = structured[:error]

      assert_equal(JSON.parse(error_report)["error_class"], error[:error_class])
      assert_equal("***", error.dig(:details, :"sasl.password"))
      assert_equal("***", error.dig(:details, :nested, :"ssl.key.password"))
      refute_includes(text, "secret")
      assert_includes(structured[:untrusted_fields], "backtrace")
    end
  end

  context "when message is not an error report" do
    before { produce(errors_topic, "{", partition: 0) }

    it do
      assert(result[:isError])
      assert_includes(text, "is not a Karafka error report")
    end
  end

  context "when offset is a transaction marker" do
    let(:arguments) { { "partition" => 0, "offset" => 1 } }

    before { produce(errors_topic, error_report, partition: 0, type: :transactional) }

    it do
      assert(result[:isError])
      assert_includes(text, "is a transaction marker")
    end
  end

  context "when partition is empty" do
    it do
      assert(result[:isError])
      assert_includes(text, "the partition is empty")
    end
  end

  context "when offset is beyond the data" do
    let(:arguments) { { "partition" => 0, "offset" => 100 } }

    before { produce(errors_topic, error_report, partition: 0) }

    it do
      assert(result[:isError])
      assert_includes(text, "its offsets are 0 to 0")
    end
  end

  context "when partition does not exist" do
    let(:arguments) { { "partition" => 10, "offset" => 0 } }

    it { assert(result[:isError]) }
  end

  context "when arguments are missing" do
    let(:arguments) { { "partition" => 0 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
