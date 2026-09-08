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
  let(:contract) { described_class.new }
  let(:result) { contract.call(params) }
  let(:params) do
    {
      topic_name: "valid-topic.name_1",
      partitions_count: 3,
      replication_factor: 1
    }
  end

  context "when everything is valid" do
    it { assert(result.success?) }
  end

  context "when the topic name is empty" do
    before { params[:topic_name] = "" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:topic_name)) }
  end

  context "when the topic name contains invalid characters" do
    before { params[:topic_name] = "invalid topic" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:topic_name)) }
  end

  context "when the topic name is too long" do
    before { params[:topic_name] = "a" * 250 }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:topic_name)) }
  end

  context "when the partitions count is below one" do
    before { params[:partitions_count] = 0 }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:partitions_count)) }
  end

  context "when the replication factor is below one" do
    before { params[:replication_factor] = 0 }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:replication_factor)) }
  end
end
