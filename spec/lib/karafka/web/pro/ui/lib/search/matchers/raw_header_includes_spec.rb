# frozen_string_literal: true

RSpec.describe Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawHeaderIncludes do
  subject(:matcher) { described_class.new }

  describe '.active?' do
    it { expect(described_class.active?(rand.to_s)).to eq(true) }
  end

  describe '#call' do
    let(:phrase) { 'test phrase' }
    let(:message) { instance_double(Karafka::Messages::Message, raw_headers: raw_headers) }

    context 'when the raw headers include the phrase in a key' do
      let(:raw_headers) { { 'test phrase' => 'some value' } }

      it 'returns true' do
        expect(matcher.call(message, phrase)).to be true
      end
    end

    context 'when the raw headers include the phrase in a value' do
      let(:raw_headers) { { 'some key' => 'test phrase' } }

      it 'returns true' do
        expect(matcher.call(message, phrase)).to be true
      end
    end

    context 'when the raw headers do not include the phrase' do
      let(:raw_headers) { { 'some key' => 'some value' } }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end

    context 'when there is an encoding compatibility error in a key' do
      let(:raw_headers) { { 'test phrase'.encode('ASCII-8BIT') => 'some value' } }
      let(:phrase) { 'test phrase-ó'.encode('UTF-8') }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end

    context 'when there is an encoding compatibility error in a value' do
      let(:raw_headers) { { 'some key' => 'test phrase'.encode('ASCII-8BIT') } }
      let(:phrase) { 'test phrase-ó'.encode('UTF-8') }

      it 'returns false' do
        expect(matcher.call(message, phrase)).to be false
      end
    end
  end

  describe '.name' do
    it 'returns the correct name for the matcher' do
      expect(described_class.name).to eq('Raw header includes')
    end
  end
end
