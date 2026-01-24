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
  subject(:trace_command) { described_class.new({}) }

  let(:dispatcher) { Karafka::Web::Pro::Commanding::Dispatcher }
  let(:test_thread) { Thread.new { sleep(0.5) } }
  let(:process_pid) { Karafka::Web.config.tracking.consumers.sampler.process_id }

  before do
    allow(dispatcher).to receive(:result)
    sleep(0.05)
  end

  after do
    test_thread.kill
    test_thread.join
  end

  it 'expect to collect and publish threads backtraces to Kafka' do
    trace_command.call

    expect(dispatcher).to have_received(:result) do |action, pid, threads_info|
      expect(threads_info).to be_a(Hash)
      expect(pid).to eq(process_pid)
      expect(action).to eq('consumers.trace')

      thread_info = threads_info.values.first
      expect(thread_info[:label]).to include('Thread TID-')
      expect(thread_info[:backtrace]).to be_a(String)
    end
  end

  context 'when process to which we send request is an embedded one' do
    before { allow(Karafka::Process).to receive(:tags).and_return(%w[embedded]) }

    it 'expect to handle it without any issues' do
      trace_command.call

      expect(dispatcher).to have_received(:result) do |action, pid, threads_info|
        expect(threads_info).to be_a(Hash)
        expect(pid).to eq(process_pid)
        expect(action).to eq('consumers.trace')

        thread_info = threads_info.values.first
        expect(thread_info[:label]).to include('Thread TID-')
        expect(thread_info[:backtrace]).to be_a(String)
      end
    end
  end
end
