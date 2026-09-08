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
      duration: "60",
      prevent_override: true
    }
  end

  context "when everything is valid" do
    it { assert(result.success?) }
  end

  context "when the duration is zero (indefinite pause)" do
    before { params[:duration] = "0" }

    it { assert(result.success?) }
  end

  context "when the duration is negative" do
    before { params[:duration] = "-5" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:duration)) }
  end

  context "when the duration is non-numeric" do
    before { params[:duration] = "abc" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:duration)) }
  end

  context "when the duration is blank" do
    before { params[:duration] = "" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:duration)) }
  end

  context "when the duration is not a string" do
    before { params[:duration] = 60 }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:duration)) }
  end

  context "when the duration key is missing" do
    before { params.delete(:duration) }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:duration)) }
  end

  context "when prevent_override is not a boolean" do
    before { params[:prevent_override] = "on" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:prevent_override)) }
  end
end
