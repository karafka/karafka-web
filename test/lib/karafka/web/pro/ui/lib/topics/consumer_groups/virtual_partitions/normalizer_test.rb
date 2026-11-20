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
  let(:params) { Karafka::Web::Ui::Controllers::Requests::Params.new(raw) }
  let(:result) { described_class.call(params) }
  let(:estimator_config) { Karafka::App.config.consumer_groups.virtual_partitions.estimator }

  context "when all the values are provided" do
    let(:raw) do
      {
        "concurrency" => "7",
        "distribution" => "balanced",
        "batch_size" => "50",
        "sample_size" => "100000"
      }
    end

    it do
      assert_equal(
        { concurrency: "7", distribution: "balanced", batch_size: "50", sample_size: "100000" },
        result
      )
    end
  end

  context "when values carry trailing garbage" do
    let(:raw) { { "concurrency" => "5abc", "batch_size" => "1.5" } }

    it "keeps them verbatim instead of truncating them" do
      assert_equal("5abc", result[:concurrency])
      assert_equal("1.5", result[:batch_size])
    end
  end

  context "when values are missing" do
    let(:raw) { {} }

    it "uses the estimator defaults" do
      assert_equal(Karafka::App.config.concurrency.to_s, result[:concurrency])
      assert_equal(Karafka::App.config.max_messages.to_s, result[:batch_size])
      assert_equal(estimator_config.distribution.to_s, result[:distribution])
      assert_equal(estimator_config.sample_size.to_s, result[:sample_size])
    end
  end

  context "when the app defaults are over the Web UI maximums" do
    let(:raw) { {} }

    before do
      vp_config = Karafka::Web.config.ui.topics.consumer_groups.virtual_partitions
      vp_config.stubs(:max_concurrency).returns(2)
      vp_config.stubs(:max_batch_size).returns(3)
    end

    it "caps them" do
      assert_equal("2", result[:concurrency])
      assert_equal("3", result[:batch_size])
    end
  end

  context "when the estimator default sample size is not an allowed one" do
    let(:raw) { {} }

    before do
      Karafka::Web.config.ui.topics.consumer_groups.virtual_partitions.stubs(:sample_sizes).returns([500, 200])
    end

    it "uses the smallest allowed sample size" do
      assert_equal("200", result[:sample_size])
    end
  end
end
