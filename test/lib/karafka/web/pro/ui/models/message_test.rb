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
  describe "#topic_page" do
    let(:result) { described_class.topic_page(topic, partitions_ids, page) }

    let(:topic) { create_topic(partitions: 4) }
    let(:partitions_ids) { (0..3).to_a }
    let(:page) { 1 }

    context "when there is no data in any of the partitions" do
      it { assert_equal([[], false], result) }
    end

    context "when we try to reach beyond first page on empty" do
      let(:page) { 2 }

      it { assert_equal([[], false], result) }
    end

    context "when there is some data in the first partition only" do
      before { produce_many(topic, (0..3).map(&:to_s), partition: 0) }

      it "expect to return this data" do
        assert_equal([3, 2, 1, 0], result[0].map(&:offset))
        refute(result[1])
      end
    end

    context "when there is some data in each of the partitions" do
      before do
        produce(topic, "0", partition: 0)
        produce(topic, "1", partition: 1)
        produce(topic, "2", partition: 2)
        produce(topic, "3", partition: 3)
      end

      it "expect to return this data" do
        assert_equal([0, 0, 0, 0], result[0].map(&:offset))
        assert_equal([0, 1, 2, 3], result[0].map(&:partition))
        refute(result[1])
      end
    end

    context "when there are more partitions than space on the first page but data only beyond" do
      let(:topic) { create_topic(partitions: 100) }
      let(:partitions_ids) { (25..29).to_a }

      before do
        produce(topic, "0", partition: 24)
        produce(topic, "0", partition: 25)
        produce(topic, "1", partition: 26)
        produce(topic, "2", partition: 27)
        produce(topic, "3", partition: 28)
      end

      it "expect to fetch from partitions we want" do
        assert_equal([0, 0, 0, 0], result[0].map(&:offset))
        assert_equal((25..28).to_a, result[0].map(&:partition))
        refute(result[1])
      end
    end
  end
end
