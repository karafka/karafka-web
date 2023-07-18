# frozen_string_literal: true

RSpec.describe_current do
  let(:message) { instance_double('Karafka::Messages::Message') }
  let(:raw_payload) { '{"key":"value"}' }

  before do
    allow(message).to receive(:raw_payload).and_return(raw_payload)
  end

  it 'calls JSON.parse with raw_payload and symbolize_names: true' do
    expect(JSON).to receive(:parse).with(raw_payload, symbolize_names: true)
    subject.call(message)
  end

  context 'when JSON is parsed successfully' do
    let(:result) { subject.call(message) }

    it 'returns a hash' do
      expect(result).to be_a(Hash)
    end

    it 'returns a hash with symbolized keys' do
      expect(result.keys.all? { |key| key.is_a?(Symbol) }).to be(true)
    end

    it 'returns a hash with expected values' do
      expect(result).to eq({key: 'value'})
    end
  end

  context 'when JSON parsing fails' do
    let(:raw_payload) { "invalid json" }

    it 'raises a JSON::ParserError' do
      expect { subject.call(message) }.to raise_error(JSON::ParserError)
    end
  end
end
