# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new }

  describe '.active?' do
    it { expect(described_class.active?(rand.to_s)).to be(true) }
  end

  describe '#call' do
    let(:phrase) { 'test phrase' }
    let(:headers) { {} }

    let(:message) do
      instance_double(
        Karafka::Messages::Message,
        raw_payload: raw_payload,
        raw_headers: headers
      )
    end

    context 'when the raw payload includes the phrase' do
      let(:raw_payload) { 'This is a test phrase in the message.' }

      it 'returns true' do
        expect(matcher.call(message, phrase)).to be true
      end
    end

    context 'when the raw payload is nil (tombstone)' do
      let(:raw_payload) { nil }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end

    context 'when the raw payload does not include the phrase' do
      let(:raw_payload) { 'This message does not contain the search term.' }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end

    context 'when there is an encoding compatibility error' do
      let(:raw_payload) { 'This is a test phrase in the message.'.encode('ASCII-8BIT') }
      let(:phrase) { 'test phrase-ó'.encode('UTF-8') }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end

    context 'when message has a zlib header but payload is not zlibed' do
      let(:raw_payload) { 'This is a test phrase in the message.' }
      let(:headers) { { 'zlib' => 'true' } }

      it 'returns true on match' do
        expect(matcher.call(message, phrase)).to be true
      end
    end

    context 'when message has a zlib header and payload is zlibed' do
      let(:raw_payload) { Zlib.deflate('This is a test phrase in the message.') }
      let(:headers) { { 'zlib' => 'true' } }

      it 'returns true on match' do
        expect(matcher.call(message, phrase)).to be true
      end
    end

    context 'when message has no zlib header and payload is zlibed' do
      let(:raw_payload) { Zlib.deflate('This is a test phrase in the message.') }

      it 'returns false on match' do
        expect(matcher.call(message, phrase)).to be false
      end
    end
  end

  describe '.name' do
    it 'returns the correct name for the matcher' do
      expect(described_class.name).to eq('Raw payload includes')
    end
  end
end
