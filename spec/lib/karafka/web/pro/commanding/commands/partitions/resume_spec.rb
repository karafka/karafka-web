# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

RSpec.describe_current do
  subject(:command) { described_class.new(command_request) }

  let(:command_request) { Karafka::Web::Pro::Commanding::Request.new(command_details) }
  let(:command_details) { { test: true } }
  let(:tracker) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker.instance }

  before do
    allow(Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker)
      .to receive(:instance)
      .and_return(tracker)
    allow(tracker).to receive(:<<)
    allow(command).to receive(:acceptance)
  end

  describe "#call" do
    it "delegates the command to tracker and sends acceptance" do
      command.call

      expect(tracker).to have_received(:<<).with(command_request)
      expect(command).to have_received(:acceptance).with(command_details)
    end
  end
end
