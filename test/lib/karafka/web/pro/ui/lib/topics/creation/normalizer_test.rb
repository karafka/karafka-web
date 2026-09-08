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

  context "when all fields are provided" do
    let(:raw) do
      {
        "topic_name" => "orders",
        "partitions_count" => "3",
        "replication_factor" => "1"
      }
    end

    it "coerces the name to a string and the counts to integers" do
      assert_equal("orders", result[:topic_name])
      assert_equal(3, result[:partitions_count])
      assert_equal(1, result[:replication_factor])
    end
  end

  context "when fields are missing" do
    let(:raw) { {} }

    it "defaults to an empty name and zero counts" do
      assert_equal("", result[:topic_name])
      assert_equal(0, result[:partitions_count])
      assert_equal(0, result[:replication_factor])
    end
  end
end
