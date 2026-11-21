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
  let(:arguments) { {} }
  let(:structured) { result.fetch(:structuredContent) }
  let(:errors_topic) { create_topic(partitions: 2) }
  let(:error_report) { Fixtures.errors_file }

  before { Karafka::Web.config.topics.errors.name = errors_topic }

  context "when there are no errors" do
    it do
      refute(result[:isError])
      assert_empty(structured[:errors])
      assert_nil(structured[:next_page])
    end
  end

  context "when there are errors in many partitions" do
    before do
      produce(errors_topic, error_report, partition: 0)
      produce(errors_topic, error_report, partition: 1)
      produce(errors_topic, "not an error report", partition: 1)
    end

    it "lists our reports from all partitions" do
      errors = structured[:errors]

      assert_equal([0, 1], errors.map { |error| error[:partition] }.sort)
      assert_equal(%w[error_message], structured[:untrusted_fields])
      assert_nil(structured[:next_page])
    end
  end

  context "when error message is long" do
    let(:error_report) do
      report = JSON.parse(Fixtures.errors_file)
      report["error_message"] = ("a" * 200) + "b"
      report.to_json
    end

    before { produce(errors_topic, error_report) }

    it "cuts it as the Web UI does" do
      assert_equal("a" * 200, structured.dig(:errors, 0, :error_message))
    end
  end

  context "when there are more errors than fit on a page" do
    let(:per_page) { Karafka::Web.config.ui.per_page }

    before { produce_many(errors_topic, Array.new(per_page + 1) { error_report }) }

    it "pages through them" do
      assert_equal(per_page, structured[:errors].size)
      assert_equal(2, structured[:next_page])

      second = described_class.new({ "page" => 2 }).call.fetch(:structuredContent)

      assert_equal(1, second[:errors].size)
      assert_nil(second[:next_page])
    end
  end

  context "when page is invalid" do
    let(:arguments) { { "page" => 0 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end

  context "when errors topic does not exist" do
    let(:errors_topic) { generate_topic_name }

    it { assert(result[:isError]) }
  end
end
