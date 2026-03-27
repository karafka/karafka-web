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
  let(:command) { described_class.new(command_request) }

  let(:command_request) { Karafka::Web::Pro::Commanding::Request.new(command_details) }
  let(:command_details) { { test: true } }
  let(:tracker) { stub }

  before do
    Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker.stubs(:instance).returns(tracker)

    tracker.stubs(:<<)
    command.stubs(:acceptance)
  end

  describe "#call" do
    it "delegates the command to tracker and sends acceptance" do
      tracker.expects(:<<).with(command_request)
      command.expects(:acceptance).with(command_details)
      command.call
    end
  end
end
