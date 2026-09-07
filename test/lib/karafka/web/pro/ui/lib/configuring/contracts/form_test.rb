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
  let(:params) { { property_value: "12345" } }

  context "when the value is present" do
    it { assert(result.success?) }
  end

  context "when the value is empty" do
    before { params[:property_value] = "" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:property_value)) }
  end

  context "when the value is not a string" do
    before { params[:property_value] = 123 }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:property_value)) }
  end

  context "when the value key is missing" do
    before { params.delete(:property_value) }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:property_value)) }
  end
end
