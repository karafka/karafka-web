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

  let(:source_message) do
    stub(raw_payload: '{"a":1}', headers: {}, key: nil, topic: "src", partition: 0, offset: 0)
  end

  let(:params) do
    {
      target_topic: "dst",
      target_partition: "",
      include_source_headers: false,
      skip_validation: false,
      target_partitions_count: 3,
      source_message: source_message
    }
  end

  # Unrouted target by default, so the consistency rule no-ops unless a test opts in
  before { ::Karafka::Routing::Router.stubs(:find_by).returns(nil) }

  context "when everything is valid" do
    it { assert(result.success?) }
  end

  context "when the target topic is blank" do
    before { params[:target_topic] = "" }

    it { refute(result.success?) }
  end

  context "when the target topic does not exist" do
    before { params[:target_partitions_count] = nil }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:target_topic)) }
  end

  context "when the target partition is within range" do
    before { params[:target_partition] = "2" }

    it { assert(result.success?) }
  end

  context "when the target partition is out of range" do
    before { params[:target_partition] = "3" }

    it { refute(result.success?) }
    it { assert(result.errors.key?(:target_partition)) }
  end

  context "when the target partition is not numeric" do
    before { params[:target_partition] = "abc" }

    it { refute(result.success?) }
  end

  context "when the target topic is unknown but a partition is given" do
    before do
      params[:target_partitions_count] = nil
      params[:target_partition] = "5"
    end

    it "reports the unknown topic and skips the partition range check" do
      refute(result.success?)
      assert(result.errors.key?(:target_topic))
      refute(result.errors.key?(:target_partition))
    end
  end

  context "when the payload is not consumable by the target's deserializer" do
    before do
      target = stub(
        deserializers?: true,
        deserializers: stub(payload: Karafka::Deserializers::Payload.new)
      )
      ::Karafka::Routing::Router.stubs(:find_by).with(name: "dst").returns(target)
      source_message.stubs(:raw_payload).returns("{ not json")
    end

    it { refute(result.success?) }
    it { assert(result.errors.key?(:payload)) }
  end

  context "when payload validation is skipped" do
    before do
      params[:skip_validation] = true
      source_message.stubs(:raw_payload).returns("{ not json")
    end

    it { assert(result.success?) }
  end
end
