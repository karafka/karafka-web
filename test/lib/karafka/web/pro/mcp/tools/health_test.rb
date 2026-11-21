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
    it "returns the per-topic health" do
      refute(result[:isError])

      consumer_groups = structured.fetch(:consumer_groups)

      refute_empty(consumer_groups)

      consumer_groups.each_value do |details|
        assert_includes(details.keys, :rebalanced_at)
        refute_empty(details.fetch(:topics))

        details.fetch(:topics).each_value do |topic|
          %i[name partitions_count lag_hybrid max_lag max_lag_partition_id lso_risk_state]
            .each { |key| assert_includes(topic.keys, key) }

          refute_includes(topic.keys, :partitions)
        end
      end

      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
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
