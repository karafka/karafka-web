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
  let(:matcher) { described_class.new(msg) }

  let(:msg) do
    stub(payload: { matchers: matchers })
  end

  let(:matchers) { { partition_id: 0 } }

  let(:consumer_group) do
    stub(id: "my_consumer_group")
  end

  let(:topic) do
    stub(name: "my_topic", consumer_group: consumer_group)
  end

  let(:assignments) { { topic => [0, 1, 2] } }

  before do
    Karafka::App.stubs(:assignments).returns(assignments)
  end

  describe "#apply?" do
    context "when partition_id is not specified in matchers" do
      let(:matchers) { {} }

      it { refute(matcher.apply?) }
    end

    context "when partition_id is specified in matchers" do
      let(:matchers) { { partition_id: 0 } }

      it { assert(matcher.apply?) }
    end
  end

  describe "#matches?" do
    context "when partition_id matches an assigned partition" do
      let(:matchers) { { partition_id: 0 } }

      it { assert(matcher.matches?) }
    end

    context "when partition_id does not match any assigned partition" do
      let(:matchers) { { partition_id: 99 } }

      it { refute(matcher.matches?) }
    end

    context "when there are no assignments" do
      let(:assignments) { {} }
      let(:matchers) { { partition_id: 0 } }

      it { refute(matcher.matches?) }
    end

    context "with multiple topics" do
      let(:topic2) do
        stub(name: "other_topic", consumer_group: consumer_group)
      end
      let(:assignments) { { topic => [0, 1], topic2 => [5, 6] } }

      context "when partition exists in any topic" do
        let(:matchers) { { partition_id: 5 } }

        it { assert(matcher.matches?) }
      end

      context "when partition does not exist in any topic" do
        let(:matchers) { { partition_id: 99 } }

        it { refute(matcher.matches?) }
      end

      context "when partition exists in first topic" do
        let(:matchers) { { partition_id: 0 } }

        it { assert(matcher.matches?) }
      end
    end
  end
end
