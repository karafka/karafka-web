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
  let(:result) { contract.call(params) }

  let(:params) do
    {
      payload: "hello",
      payload_file: nil,
      key: "",
      partition: "",
      headers: "",
      partitions_count: 3
    }
  end

  context "when everything is valid" do
    it { assert(result.success?) }
  end

  context "when the payload is arbitrary non-JSON text" do
    before { params[:payload] = "not json at all" }

    it { assert(result.success?) }
  end

  context "when a header line is malformed" do
    before { params[:headers] = "a: b\nno-colon" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:headers)) }
  end

  context "when blank header lines are present" do
    before { params[:headers] = "a: b\n\n" }

    it { assert(result.success?) }
  end

  context "when the partition is within range" do
    before { params[:partition] = "2" }

    it { assert(result.success?) }
  end

  context "when the partition is out of range" do
    before { params[:partition] = "3" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition)) }
  end

  context "when the partition is not numeric" do
    before { params[:partition] = "abc" }

    it { refute(result.success?) }
  end

  context "when both the headers and the partition are invalid" do
    before do
      params[:headers] = "no-colon"
      params[:partition] = "999"
    end

    it "reports both independently" do
      refute(result.success?)
      assert(result.errors.key?(:headers))
      assert(result.errors.key?(:partition))
    end
  end
end
