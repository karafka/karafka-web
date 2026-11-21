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

  context "when there is state" do
    let(:process) { structured.fetch(:processes).first }

    it "returns the active processes" do
      refute(result[:isError])
      assert_equal(1, structured.fetch(:processes).size)
      assert_equal(%w[tags], structured.fetch(:untrusted_fields))
      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end

    it "maps the process report" do
      assert_equal("shinra:1:1", process[:id])
      assert_equal("running", process[:status])
      assert_in_delta(2_690_818_651.82293, process[:started_at])
      assert_equal(123_852, process[:memory_usage])
      assert_equal(26_421_728, process[:memory_total_usage])
      assert_equal(32_763_220, process[:memory_size])
      assert_equal([1.33, 1.1, 1.1], process[:cpu_usage])
      assert_in_delta(5.634919553399087, process[:utilization])
      assert_equal(5, process[:workers])
      assert_equal(1, process[:busy])
      assert_equal(1, process[:running_jobs])
      assert_equal(0, process[:pending_jobs])
      assert_equal(213_731_273, process[:lag_hybrid])
      assert_equal(%w[default test2 visits], process[:subscribed_topics])
      assert_equal(["#8cbff36"], process[:tags])
    end
  end

  context "when a process report has an incompatible schema" do
    let(:reports_topic) { create_topic }

    before do
      report = Fixtures.consumers_reports_json
      report[:schema_version] = "0.1"
      Karafka::Web.config.topics.consumers.reports.name = reports_topic
      produce(reports_topic, report.to_json)
    end

    it "does not list it" do
      refute(result[:isError])
      assert_empty(structured.fetch(:processes))
    end
  end

  context "when state is missing" do
    before { Karafka::Web.config.topics.consumers.states.name = create_topic }

    it "returns a tool error" do
      assert(result[:isError])
      assert_includes(result.dig(:content, 0, :text), "Status page")
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "topic" => "test" } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
