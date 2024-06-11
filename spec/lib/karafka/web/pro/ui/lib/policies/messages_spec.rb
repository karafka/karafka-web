# frozen_string_literal: true

RSpec.describe_current do
  subject(:policy) { described_class.new }

  describe '#key?' do
    it { expect(policy.key?('irrelevant')).to eq(true) }
  end

  describe '#headers?' do
    it { expect(policy.headers?('irrelevant')).to eq(true) }
  end

  describe '#payload?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(policy.payload?(message)).to eq(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(policy.payload?(message)).to eq(false) }
    end
  end

  describe '#download?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(policy.download?(message)).to eq(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(policy.download?(message)).to eq(false) }
    end
  end

  describe '#export?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(policy.export?(message)).to eq(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(policy.export?(message)).to eq(false) }
    end
  end

  describe '#republish?' do
    it { expect(policy.republish?(nil)).to eq(true) }
  end
end
