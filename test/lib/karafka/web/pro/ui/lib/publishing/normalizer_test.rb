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
  let(:params) { Karafka::Web::Ui::Controllers::Requests::Params.new(raw) }
  let(:result) { described_class.call(params) }

  context "when nothing is provided" do
    let(:raw) { {} }

    it "defaults every field to empty with no file and no tombstone" do
      assert_equal("", result[:payload])
      assert_nil(result[:payload_file])
      assert_equal("", result[:key])
      assert_equal("", result[:partition])
      assert_equal("", result[:headers])
      refute(result[:tombstone])
      refute(result[:skip_validation])
    end
  end

  context "when the skip_validation checkbox is on" do
    let(:raw) { { "skip_validation" => "on" } }

    it { assert(result[:skip_validation]) }
  end

  context "when the tombstone checkbox is on" do
    let(:raw) { { "tombstone" => "on" } }

    it { assert(result[:tombstone]) }
  end

  context "when the tombstone checkbox is off" do
    let(:raw) { { "tombstone" => "off" } }

    it { refute(result[:tombstone]) }
  end

  context "when the fields are provided" do
    let(:raw) do
      {
        "payload" => "hello",
        "key" => "k1",
        "partition" => "2",
        "headers" => "a: b"
      }
    end

    it "coerces them to strings verbatim" do
      assert_equal("hello", result[:payload])
      assert_equal("k1", result[:key])
      assert_equal("2", result[:partition])
      assert_equal("a: b", result[:headers])
    end
  end

  context "when a file is uploaded" do
    let(:file_content) { "binary\x00data".b }
    let(:tempfile) do
      file = Tempfile.new(%w[payload .bin])
      file.binmode
      file.write(file_content)
      file.rewind
      file
    end
    let(:raw) { { "payload_file" => { tempfile: tempfile, filename: "payload.bin" } } }

    it "reads the file bytes into payload_file" do
      assert_equal(file_content, result[:payload_file])
    end

    it "reads the full bytes even when called twice (rewinds the tempfile)" do
      described_class.call(params)

      assert_equal(file_content, described_class.call(params)[:payload_file])
    end
  end

  context "when the payload_file field is blank (no file selected)" do
    let(:raw) { { "payload_file" => "" } }

    it "treats it as no file" do
      assert_nil(result[:payload_file])
    end
  end
end
