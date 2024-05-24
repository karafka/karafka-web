# frozen_string_literal: true

RSpec.describe_current do
  subject(:matcher) { described_class.new }

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
