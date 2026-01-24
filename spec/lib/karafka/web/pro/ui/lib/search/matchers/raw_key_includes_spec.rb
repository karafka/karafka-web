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
  subject(:matcher) { described_class.new }

  describe '.active?' do
    it { expect(described_class.active?(rand.to_s)).to be(true) }
  end

  describe '#call' do
    let(:phrase) { 'test phrase' }
    let(:message) { instance_double(Karafka::Messages::Message, raw_key: raw_key) }

    context 'when the raw key includes the phrase' do
      let(:raw_key) { 'This is a test phrase in the key.' }

      it 'returns true' do
        expect(matcher.call(message, phrase)).to be true
      end
    end

    context 'when the raw key does not include the phrase' do
      let(:raw_key) { 'This key does not contain the search term.' }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end

    context 'when there is an encoding compatibility error' do
      let(:raw_key) { 'This is a test phrase in the key.'.encode('ASCII-8BIT') }
      let(:phrase) { 'test phrase-ó'.encode('UTF-8') }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end
  end

  describe '.name' do
    it 'returns the correct name for the matcher' do
      expect(described_class.name).to eq('Raw key includes')
    end
  end
end
