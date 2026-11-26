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
  let(:checks) { structured.fetch(:checks) }
  let(:topics_config) { Karafka::Web.config.topics }

  before { produce(TOPICS[0], Fixtures.consumers_states_file) }

  context "when all that is needed is there" do
    it "returns every Status page check and the components versions" do
      refute(result[:isError])

      assert_equal(Karafka::Web::Ui::Models::Status::CHECKS.keys, checks.keys)
      assert_equal(:success, checks.dig(:enabled, :status))
      assert_equal(:success, checks.dig(:connection, :status))
      assert_equal(:success, checks.dig(:topics, :status))
      assert_equal(:success, checks.dig(:initial_consumers_state, :status))
      assert(checks.dig(:topics, :details, topics_config.errors.name, :present))

      assert_equal(Karafka::VERSION, structured.dig(:components, :karafka))
      assert_equal(Karafka::Web::VERSION, structured.dig(:components, :karafka_web))
      assert_equal(WaterDrop::VERSION, structured.dig(:components, :waterdrop))

      assert_equal(JSON.parse(structured.to_json), JSON.parse(result.dig(:content, 0, :text)))
    end
  end

  context "when topics are missing" do
    before do
      topics_config.consumers.states.name = generate_topic_name
      topics_config.consumers.metrics.name = generate_topic_name
      topics_config.consumers.reports.name = generate_topic_name
      topics_config.errors.name = generate_topic_name
    end

    it "returns the failed check and halts the checks that depend on it" do
      refute(result[:isError])

      assert_equal(:failure, checks.dig(:topics, :status))
      refute(checks.dig(:topics, :details, topics_config.errors.name, :present))
      assert_equal(:halted, checks.dig(:partitions, :status))
      assert_equal(:halted, checks.dig(:initial_consumers_state, :status))
    end
  end

  context "when arguments are given" do
    let(:arguments) { { "what" => 1 } }

    it { assert_raises(Karafka::Web::Errors::Mcp::InvalidArgumentsError) { result } }
  end
end
