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
  describe ".json" do
    let(:response) { described_class.json({ id: 1 }) }

    it do
      assert_equal(200, response[0])
      assert_equal("application/json", response[1]["content-type"])
      assert_equal(['{"id":1}'], response[2])
    end
  end

  describe ".accepted" do
    it { assert_equal([202, {}, []], described_class.accepted) }
  end

  describe ".method_not_allowed" do
    let(:response) { described_class.method_not_allowed }

    it do
      assert_equal(405, response[0])
      assert_equal("POST", response[1]["allow"])
    end
  end

  describe ".http_error" do
    let(:response) { described_class.http_error(415, "Unsupported Media Type") }

    it do
      assert_equal(415, response[0])
      assert_equal(["Unsupported Media Type"], response[2])
    end
  end
end
