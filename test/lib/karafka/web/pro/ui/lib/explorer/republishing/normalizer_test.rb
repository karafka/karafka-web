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

  context "when nothing is provided" do
    let(:raw) { {} }

    it "defaults to blank strings and false flags" do
      assert_equal("", result[:target_topic])
      assert_equal("", result[:target_partition])
      refute(result[:include_source_headers])
      refute(result[:skip_validation])
    end
  end

  context "when the fields are provided" do
    let(:raw) do
      {
        "target_topic" => "dst",
        "target_partition" => "2",
        "include_source_headers" => "on",
        "skip_validation" => "on"
      }
    end

    it "coerces the values" do
      assert_equal("dst", result[:target_topic])
      assert_equal("2", result[:target_partition])
      assert(result[:include_source_headers])
      assert(result[:skip_validation])
    end
  end

  context "when the checkboxes are off" do
    let(:raw) { { "include_source_headers" => "off", "skip_validation" => "off" } }

    it do
      refute(result[:include_source_headers])
      refute(result[:skip_validation])
    end
  end
end
