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
  let(:listener) { described_class.new }
  let(:iterator_double) { instance_double(Karafka::Pro::Iterator) }
  let(:message) { instance_double(Karafka::Messages::Message) }

  before do
    allow(Karafka::Pro::Iterator).to receive(:new).and_return(iterator_double)
    allow(Karafka.monitor).to receive(:instrument)
  end

  describe '#each' do
    context 'when all good' do
      before { allow(iterator_double).to receive(:each).and_yield(message) }

      it 'yields messages from the iterator' do
        expect { |b| listener.each(&b) }.to yield_with_args(message)
      end
    end

    context 'when an error occurs' do
      before do
        allow(iterator_double)
          .to receive(:each)
          .and_raise(StandardError)
          .and_yield(message)

        allow(Karafka.monitor).to receive(:instrument)
      end

      it 'reports the error and retries' do
        listener.each do
          listener.stop
        end

        expect(Karafka.monitor).to have_received(:instrument)
      end
    end

    context 'when stop is requested' do
      before do
        allow(iterator_double).to receive(:each).and_yield(message)
        allow(iterator_double).to receive(:stop)
      end

      it 'stops iterating over messages' do
        listener.stop
        listener.each { |_| nil }

        expect(iterator_double).to have_received(:stop)
      end
    end
  end
end
