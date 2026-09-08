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

  describe "#seek" do
    let(:result) { described_class.seek(params) }
    let(:raw) do
      {
        "offset" => "100",
        "prevent_overtaking" => "on",
        "force_resume" => "off"
      }
    end

    it "keeps the offset as a raw string for the contract to validate" do
      assert_equal("100", result[:offset])
    end

    it "coerces the boolean flags" do
      assert(result[:prevent_overtaking])
      refute(result[:force_resume])
    end

    context "when the offset is non-numeric" do
      let(:raw) { { "offset" => "abc" } }

      it "keeps it verbatim (so the contract rejects it) instead of coercing to 0" do
        assert_equal("abc", result[:offset])
      end
    end

    context "when the fields are entirely absent" do
      let(:raw) { {} }

      it "defaults without raising" do
        assert_equal("", result[:offset])
        refute(result[:prevent_overtaking])
        refute(result[:force_resume])
      end
    end
  end

  describe "#pause" do
    let(:result) { described_class.pause(params) }
    let(:raw) do
      {
        "duration" => "60",
        "prevent_override" => "on"
      }
    end

    it "keeps the duration (in seconds) as a raw string for the contract to validate" do
      assert_equal("60", result[:duration])
    end

    it "coerces the prevent_override flag" do
      assert(result[:prevent_override])
    end

    context "when the fields are entirely absent" do
      let(:raw) { {} }

      it "defaults without raising" do
        assert_equal("", result[:duration])
        refute(result[:prevent_override])
      end
    end
  end

  describe "#resume" do
    let(:result) { described_class.resume(params) }
    let(:raw) { { "reset_attempts" => "yes" } }

    it "coerces the reset_attempts flag" do
      assert(result[:reset_attempts])
    end

    context "when reset_attempts is off" do
      let(:raw) { { "reset_attempts" => "off" } }

      it { refute(result[:reset_attempts]) }
    end
  end
end
