# frozen_string_literal: true

RSpec.describe_current do
  subject(:parsing) { described_class.new.call(message) }

  let(:message) { instance_double('Karafka::Messages::Message') }
  let(:raw_payload) { '{"key":"value"}' }

  before do
    allow(message).to receive(:raw_payload).and_return(raw_payload)
  end

  context 'when JSON is parsed successfully' do
    it 'returns a hash' do
      expect(parsing).to be_a(Hash)
    end

    it 'returns a hash with symbolized keys' do
      expect(parsing.keys.all? { |key| key.is_a?(Symbol) }).to be(true)
    end

    it 'returns a hash with expected values' do
      expect(parsing).to eq({ key: 'value' })
    end
  end

  context 'when JSON parsing fails' do
    let(:raw_payload) { 'invalid json' }

    it 'raises a JSON::ParserError' do
      expect { parsing }.to raise_error(JSON::ParserError)
    end
  end
end
