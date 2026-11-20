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
  include described_class

  describe "#vp_verdict_badge" do
    it { assert_equal("badge-success", vp_verdict_badge(:recommended)) }
    it { assert_equal("badge-warning", vp_verdict_badge(:maybe)) }
    it { assert_equal("badge-error", vp_verdict_badge(:not_recommended)) }
    it { assert_equal("badge-secondary", vp_verdict_badge(nil)) }
  end

  describe "#vp_verdict_label" do
    it { assert_equal("Recommended", vp_verdict_label(:recommended)) }
    it { assert_equal("Not recommended", vp_verdict_label(:not_recommended)) }
    it { assert_equal("None", vp_verdict_label(nil)) }
  end

  describe "#vp_metric" do
    it { assert_equal("2.5x", vp_metric(2.5, "x")) }
    it { assert_equal("0", vp_metric(0)) }
    it { assert_equal("-", vp_metric(nil, "%")) }
  end
end
