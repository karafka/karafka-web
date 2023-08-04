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

    it { expect(manager.compatible?(message)).to eq(true) }

    it 'expect to cast to compatible after compatible message check' do
      manager.compatible?(message)
      expect(manager.to_s).to eq('compatible')
    end
  end

  context 'when it is an older version' do
    let(:schema_version) { '1.1.0' }

    it { expect(manager.compatible?(message)).to eq(true) }

    it 'expect to cast to compatible after compatible message check' do
      manager.compatible?(message)
      expect(manager.to_s).to eq('compatible')
    end
  end

  context 'when it is a newer version' do
    let(:schema_version) { '111.1.0' }

    it { expect(manager.compatible?(message)).to eq(false) }

    it 'expect to cast to incompatible after compatible message check' do
      manager.compatible?(message)
      expect(manager.to_s).to eq('incompatible')
    end
  end

  context 'when checking several and first is incompatible' do
    let(:message0) do
      OpenStruct.new(
        payload: {
          schema_version: '111.0.0'
        }
      )
    end

    let(:schema_version) { '1.1.0' }

    it 'expect not to switch back' do
      manager.compatible?(message0)
      manager.compatible?(message)

      expect(manager.to_s).to eq('incompatible')
    end
  end
end
