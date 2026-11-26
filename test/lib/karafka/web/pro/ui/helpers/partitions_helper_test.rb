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
  include Karafka::Web::Ui::Helpers::PartitionsHelper
  include Karafka::Web::Pro::Ui::Helpers::PathsHelper
  include described_class

  # PathsHelper#root_path is mixed into the app at runtime; stub it here
  def root_path(*args)
    "/karafka/#{args.join("/")}"
  end

  describe "#offset_with_label" do
    it "expect to link the offset to the explorer when exploring" do
      assert_equal(
        '<a href="/karafka/explorer/topics/visits/2/5">5</a>',
        offset_with_label("visits", 2, 5, explore: true)
      )
    end

    it "expect not to link the offset when not exploring" do
      assert_equal("5", offset_with_label("visits", 2, 5))
    end

    it "expect not to link an offset that was not committed yet" do
      assert_includes(offset_with_label("visits", 2, -1, explore: true), "N/A")
    end
  end

  describe "#normalized_metric" do
    it { assert_equal("N/A", normalized_metric(-1)) }
    it { assert_equal("10", normalized_metric(10)) }
  end

  describe "#lso_risk_state_bg" do
    def details(state)
      Struct.new(:lso_risk_state).new(state)
    end

    it { assert_equal("", lso_risk_state_bg(details(:active))) }
    it { assert_equal("bg-warning bg-opacity-25", lso_risk_state_bg(details(:at_risk))) }
    it { assert_equal("bg-error bg-opacity-25", lso_risk_state_bg(details(:stopped))) }
  end
end
