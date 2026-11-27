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
  include Karafka::Web::Ui::Helpers::BadgesHelper
  include described_class

  describe "#consumer_group_state_badge" do
    let(:result) { consumer_group_state_badge(state) }

    context "when the consumer group is stable" do
      let(:state) { :stable }

      it { assert_equal("badge-success", result) }
    end

    context "when the consumer group is empty" do
      let(:state) { :empty }

      it { assert_equal("badge-secondary", result) }
    end

    context "when the consumer group is dead" do
      let(:state) { :dead }

      it { assert_equal("badge-error", result) }
    end

    context "when the consumer group is rebalancing" do
      let(:state) { :preparing_rebalance }

      it { assert_equal("badge-warning", result) }
    end
  end
end
