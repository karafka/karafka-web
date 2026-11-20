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

  let(:params) do
    {
      concurrency: "5",
      distribution: "consistent",
      batch_size: "100",
      sample_size: "1000"
    }
  end

  context "when all values are valid" do
    it { assert(contract.call(params).success?) }
  end

  context "when distribution is balanced" do
    before { params[:distribution] = "balanced" }

    it { assert(contract.call(params).success?) }
  end

  %w[0 -1 5abc 1.5].push("").each do |value|
    context "when concurrency is #{value.inspect}" do
      before { params[:concurrency] = value }

      it do
        result = contract.call(params)

        refute(result.success?)
        assert_equal(
          "concurrency needs to be an integer that is 1 or greater",
          result.errors[:concurrency]
        )
      end
    end

    context "when batch size is #{value.inspect}" do
      before { params[:batch_size] = value }

      it do
        result = contract.call(params)

        refute(result.success?)
        assert_equal(
          "batch size needs to be an integer that is 1 or greater",
          result.errors[:batch_size]
        )
      end
    end
  end

  context "when distribution is unknown" do
    before { params[:distribution] = "random" }

    it do
      result = contract.call(params)

      refute(result.success?)
      assert(result.errors.key?(:distribution))
    end
  end

  %w[1234 0 5abc].push("").each do |value|
    context "when sample size is #{value.inspect}" do
      before { params[:sample_size] = value }

      it do
        result = contract.call(params)

        refute(result.success?)
        assert_equal(
          "sample size needs to be one of the allowed sample sizes",
          result.errors[:sample_size]
        )
      end
    end
  end

  context "when sample size is one of custom sample sizes" do
    before do
      Karafka::Web.config.ui.topics.virtual_partitions.stubs(:sample_sizes).returns([1_234])
      params[:sample_size] = "1234"
    end

    it { assert(contract.call(params).success?) }
  end
end
