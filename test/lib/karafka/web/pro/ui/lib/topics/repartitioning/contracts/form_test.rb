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
  let(:params) { { partition_count: "5" } }

  context "when the partition count is valid" do
    it { assert(result.success?) }
  end

  context "when a current partition count is supplied" do
    before { params[:current_partition_count] = 5 }

    context "when the new count is greater" do
      before { params[:partition_count] = "6" }

      it { assert(result.success?) }
    end

    context "when the new count equals the current one" do
      before { params[:partition_count] = "5" }

      it { refute(result.success?) }
      it { assert(result.errors.key?(:partition_count)) }
    end

    context "when the new count is lower" do
      before { params[:partition_count] = "4" }

      it { refute(result.success?) }
      it { assert(result.errors.key?(:partition_count)) }
    end

    ["5abc", "0", "-1", ""].each do |invalid|
      context "when the new count is #{invalid.inspect}" do
        before { params[:partition_count] = invalid }

        it { refute(result.success?) }

        it "reports it once, as a format problem" do
          assert_equal(
            "needs to be an integer that is 1 or greater",
            result.errors[:partition_count]
          )
        end
      end
    end
  end

  context "when no current partition count is supplied" do
    before { params[:partition_count] = "1" }

    it { assert(result.success?) }
  end

  context "when the partition count is zero" do
    before { params[:partition_count] = "0" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count is negative" do
    before { params[:partition_count] = "-1" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count has trailing garbage" do
    before { params[:partition_count] = "5abc" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count is fractional" do
    before { params[:partition_count] = "3.9" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count is padded with whitespace" do
    before { params[:partition_count] = " 7" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count is non-numeric" do
    before { params[:partition_count] = "abc" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count is blank" do
    before { params[:partition_count] = "" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count is not a string" do
    before { params[:partition_count] = 5 }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end

  context "when the partition count key is missing" do
    before { params.delete(:partition_count) }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partition_count)) }
  end
end
