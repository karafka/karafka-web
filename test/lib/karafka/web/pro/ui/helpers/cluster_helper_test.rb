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

  describe "#broker_load_status_row" do
    it { assert_equal("status-row-warning", broker_load_status_row(:overloaded)) }
    it { assert_equal("", broker_load_status_row(:underloaded)) }
    it { assert_equal("", broker_load_status_row(:balanced)) }
  end

  describe "#broker_load_badge" do
    it "labels an overloaded broker" do
      assert_includes(broker_load_badge(:overloaded), "overloaded")
      assert_includes(broker_load_badge(:overloaded), "badge-warning")
    end

    it "labels an underloaded broker" do
      assert_includes(broker_load_badge(:underloaded), "underloaded")
      assert_includes(broker_load_badge(:underloaded), "badge-secondary")
    end

    it "renders a muted dash for a balanced broker" do
      assert_includes(broker_load_badge(:balanced), "&mdash;")
    end
  end

  describe "#broker_out_of_sync" do
    it "renders a plain zero when everything is in sync" do
      assert_equal("0", broker_out_of_sync(0))
    end

    it "badges a positive count as a warning" do
      result = broker_out_of_sync(3)

      assert_includes(result, "badge-warning")
      assert_includes(result, "3")
    end
  end
end
