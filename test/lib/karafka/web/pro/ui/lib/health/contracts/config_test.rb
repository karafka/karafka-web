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
      ui: {
        health: {
          lags: {
            skew_threshold: 3,
            skew_minimum: 100,
            high_threshold: 10_000,
            warning_ratio: 0.5
          }
        }
      }
    }
  end

  context "when all values are valid" do
    it "is valid" do
      assert(contract.call(params).success?)
    end
  end

  context "when skew_threshold is not numeric" do
    before { params[:ui][:health][:lags][:skew_threshold] = "3" }

    it { refute(contract.call(params).success?) }
  end

  context "when skew_threshold is not positive" do
    before { params[:ui][:health][:lags][:skew_threshold] = 0 }

    it { refute(contract.call(params).success?) }
  end

  context "when skew_minimum is not an integer" do
    before { params[:ui][:health][:lags][:skew_minimum] = 1.5 }

    it { refute(contract.call(params).success?) }
  end

  context "when skew_minimum is negative" do
    before { params[:ui][:health][:lags][:skew_minimum] = -1 }

    it { refute(contract.call(params).success?) }
  end

  context "when high_threshold is not an integer" do
    before { params[:ui][:health][:lags][:high_threshold] = 10_000.5 }

    it { refute(contract.call(params).success?) }
  end

  context "when high_threshold is not positive" do
    before { params[:ui][:health][:lags][:high_threshold] = 0 }

    it { refute(contract.call(params).success?) }
  end

  context "when warning_ratio is not numeric" do
    before { params[:ui][:health][:lags][:warning_ratio] = "0.5" }

    it { refute(contract.call(params).success?) }
  end

  context "when warning_ratio is not positive" do
    before { params[:ui][:health][:lags][:warning_ratio] = 0 }

    it { refute(contract.call(params).success?) }
  end

  context "when warning_ratio is bigger than 1" do
    before { params[:ui][:health][:lags][:warning_ratio] = 1.5 }

    it { refute(contract.call(params).success?) }
  end
end
