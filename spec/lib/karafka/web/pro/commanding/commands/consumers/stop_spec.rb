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
  subject(:stop_command) { described_class.new({}) }

  before { allow(Process).to receive(:kill) }

  it 'expect to send a QUIT signal to the current process' do
    stop_command.call

    expect(Process).to have_received(:kill).with('QUIT', Process.pid)
  end

  context 'when process to which we send request is not a standalone one' do
    before { allow(Karafka::Server.execution_mode).to receive(:standalone?).and_return(false) }

    it 'expect to ignore quiet command in a swarm one' do
      stop_command.call

      expect(Process).not_to have_received(:kill)
    end
  end
end
