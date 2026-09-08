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
  describe ".call" do
    let(:search_query) do
      {
        "phrase" => "test phrase",
        "limit" => "10000",
        "matcher" => "ExampleMatcher",
        "partitions" => ["partition1", "partition2", nil, "partition1"],
        "offset_type" => "latest",
        "timestamp" => "1627381800",
        "offset" => "0"
      }
    end

    let(:normalized_query) do
      {
        phrase: "test phrase",
        limit: 10_000,
        matcher: "ExampleMatcher",
        partitions: %w[partition1 partition2],
        offset_type: "latest",
        timestamp: 1_627_381_800,
        offset: 0
      }
    end

    it "returns a normalized hash" do
      assert_equal(normalized_query, described_class.call(search_query))
    end

    context "when partitions contain nil values" do
      before { search_query["partitions"] = ["partition1", nil, "partition2", nil] }

      it "removes nil values from partitions" do
        assert_equal(%w[partition1 partition2], described_class.call(search_query)[:partitions])
      end
    end

    context "when partitions contain duplicates" do
      before { search_query["partitions"] = %w[partition1 partition1 partition2] }

      it "removes duplicate values from partitions" do
        assert_equal(%w[partition1 partition2], described_class.call(search_query)[:partitions])
      end
    end

    context "when phrase is nil" do
      before { search_query["phrase"] = nil }

      it "casts nil phrase to an empty string" do
        assert_equal("", described_class.call(search_query)[:phrase])
      end
    end

    context "when limit is a non-numeric string" do
      before { search_query["limit"] = "non-numeric" }

      it "casts non-numeric limit to 0" do
        assert_equal(0, described_class.call(search_query)[:limit])
      end
    end

    context "when matcher is nil" do
      before { search_query["matcher"] = nil }

      it "casts nil matcher to an empty string" do
        assert_equal("", described_class.call(search_query)[:matcher])
      end
    end

    context "when offset_type is nil" do
      before { search_query["offset_type"] = nil }

      it "casts nil offset_type to an empty string" do
        assert_equal("", described_class.call(search_query)[:offset_type])
      end
    end

    context "when timestamp is a non-numeric string" do
      before { search_query["timestamp"] = "non-numeric" }

      it "casts non-numeric timestamp to 0" do
        assert_equal(0, described_class.call(search_query)[:timestamp])
      end
    end

    context "when offset is a non-numeric string" do
      before { search_query["offset"] = "non-numeric" }

      it "casts non-numeric offset to 0" do
        assert_equal(0, described_class.call(search_query)[:offset])
      end
    end
  end
end
