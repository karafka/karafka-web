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
  let(:contract) { described_class.new }
  let(:params) { { mcp: { changing_tools: [], web_ui_path: "", audit: { actor: nil, fail_closed_reads: false } } } }

  it { assert(contract.call(params).success?) }

  context "when actor is a callable" do
    before { params[:mcp][:audit][:actor] = ->(_env) { "admin" } }

    it { assert(contract.call(params).success?) }
  end

  context "when actor is not a callable" do
    before { params[:mcp][:audit][:actor] = "admin" }

    it { refute(contract.call(params).success?) }
  end

  context "when changing_tools lists tool names" do
    before { params[:mcp][:changing_tools] = %w[karafka_pause_partition karafka_trace_process] }

    it { assert(contract.call(params).success?) }
  end

  context "when changing_tools lists an unknown tool name" do
    before { params[:mcp][:changing_tools] = %w[karafka_pause_partition karafka_delete_topic] }

    it { refute(contract.call(params).success?) }
  end

  context "when changing_tools lists a read-only tool name" do
    before { params[:mcp][:changing_tools] = %w[karafka_overview] }

    it { refute(contract.call(params).success?) }
  end

  context "when changing_tools is the operate preset" do
    before { params[:mcp][:changing_tools] = :operate }

    it { assert(contract.call(params).success?) }
  end

  context "when changing_tools is an unknown preset" do
    before { params[:mcp][:changing_tools] = :all }

    it { refute(contract.call(params).success?) }
  end

  context "when changing_tools is true" do
    before { params[:mcp][:changing_tools] = true }

    it { refute(contract.call(params).success?) }
  end

  context "when changing_tools lists symbols" do
    before { params[:mcp][:changing_tools] = %i[karafka_pause_partition] }

    it { refute(contract.call(params).success?) }
  end

  context "when web_ui_path is a mount path" do
    before { params[:mcp][:web_ui_path] = "/karafka" }

    it { assert(contract.call(params).success?) }
  end

  context "when web_ui_path is the root" do
    before { params[:mcp][:web_ui_path] = "/" }

    it { refute(contract.call(params).success?) }
  end

  context "when web_ui_path is relative" do
    before { params[:mcp][:web_ui_path] = "karafka" }

    it { refute(contract.call(params).success?) }
  end

  context "when fail_closed_reads is not a boolean" do
    before { params[:mcp][:audit][:fail_closed_reads] = "yes" }

    it { refute(contract.call(params).success?) }
  end
end
