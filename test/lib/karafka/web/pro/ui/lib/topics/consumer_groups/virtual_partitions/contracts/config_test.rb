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
        topics: {
          consumer_groups: {
            virtual_partitions: {
              timeout: 100,
              sample_sizes: [100, 1_000],
              max_concurrency: 10,
              max_batch_size: 100
            }
          }
        }
      }
    }
  end

  let(:vp_params) { params[:ui][:topics][:consumer_groups][:virtual_partitions] }

  context "when all values are valid" do
    it { assert(contract.call(params).success?) }
  end

  [nil, 0, -1, "100", 1.5].each do |value|
    context "when timeout is #{value.inspect}" do
      before { vp_params[:timeout] = value }

      it { refute(contract.call(params).success?) }
    end
  end

  %i[max_concurrency max_batch_size].each do |key|
    [nil, 0, -1, "10", 1.5].each do |value|
      context "when #{key} is #{value.inspect}" do
        before { vp_params[key] = value }

        it { refute(contract.call(params).success?) }
      end
    end
  end

  [nil, [], "100", [0], [-1], [1.5], [100, "1000"]].each do |value|
    context "when sample sizes are #{value.inspect}" do
      before { vp_params[:sample_sizes] = value }

      it { refute(contract.call(params).success?) }
    end
  end
end
