# frozen_string_literal: true

RSpec.describe_current do
  subject(:manager) { described_class.new }

  let(:message) do
    OpenStruct.new(
      payload: {
        schema_version: schema_version
      }
    )
  end

  it { expect(manager.to_s).to eq('compatible') }

  context 'when it is the same version as in the process' do
    let(:schema_version) { ::Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION }

    it { expect(manager.call(message)).to eq(:current) }
  end

  context 'when it is an older version' do
    let(:schema_version) { '1.1.0' }

    it { expect(manager.call(message)).to eq(:older) }
  end

  context 'when it is a newer version' do
    let(:schema_version) { '111.1.0' }

    it { expect(manager.call(message)).to eq(:newer) }
  end

  context 'when we invalidate the state' do
    before { manager.invalidate! }

    it { expect(manager.to_s).to eq('incompatible') }
  end
end
