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

  # Minimal distribution row double exposing what broker_imbalance reads
  def dist(comparable:, load_ratio:)
    Struct.new(:comparable, :load_ratio).new(comparable, load_ratio)
  end

  # Defaults: overloaded_ratio 1.5, underloaded_ratio 0.5
  describe "#broker_imbalance" do
    it "is balanced when the broker is not comparable (single broker / no partitions)" do
      assert_equal(:balanced, broker_imbalance(dist(comparable: false, load_ratio: 5.0)))
    end

    it "flags a broker leading well above its fair share as overloaded" do
      assert_equal(:overloaded, broker_imbalance(dist(comparable: true, load_ratio: 2.0)))
    end

    it "flags a broker leading well below its fair share as underloaded" do
      assert_equal(:underloaded, broker_imbalance(dist(comparable: true, load_ratio: 0.2)))
    end

    it "is balanced near its fair share" do
      assert_equal(:balanced, broker_imbalance(dist(comparable: true, load_ratio: 1.0)))
    end

    context "when the thresholds are customized via config" do
      before { ::Karafka::Web.config.ui.cluster.distribution.overloaded_ratio = 3.0 }

      after { ::Karafka::Web.config.ui.cluster.distribution.overloaded_ratio = 1.5 }

      it "respects the configured overloaded_ratio" do
        assert_equal(:balanced, broker_imbalance(dist(comparable: true, load_ratio: 2.0)))
      end
    end
  end

  describe "#broker_load_status_row" do
    it { assert_equal("status-row-warning", broker_load_status_row(:overloaded)) }
    it { assert_equal("status-row-warning", broker_load_status_row(:underloaded)) }
    it { assert_equal("", broker_load_status_row(:balanced)) }
  end

  describe "#broker_load_badge" do
    it "labels an overloaded broker" do
      assert_includes(broker_load_badge(:overloaded), "overloaded")
      assert_includes(broker_load_badge(:overloaded), "badge-warning")
    end

    it "labels an underloaded broker with a warning badge" do
      assert_includes(broker_load_badge(:underloaded), "underloaded")
      assert_includes(broker_load_badge(:underloaded), "badge-warning")
    end

    it "labels a balanced broker" do
      assert_includes(broker_load_badge(:balanced), "balanced")
      assert_includes(broker_load_badge(:balanced), "badge-success")
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
