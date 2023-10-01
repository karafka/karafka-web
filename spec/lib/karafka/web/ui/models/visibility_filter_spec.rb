# frozen_string_literal: true

RSpec.describe_current do
  subject(:filter) { described_class.new }

  describe '#key?' do
    it { expect(filter.key?('irrelevant')).to eq(true) }
  end

  describe '#headers?' do
    it { expect(filter.headers?('irrelevant')).to eq(true) }
  end

  describe '#payload?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(filter.payload?(message)).to eq(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(filter.payload?(message)).to eq(false) }
    end
  end

  describe '#download?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(filter.download?(message)).to eq(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(filter.download?(message)).to eq(false) }
    end
  end

  describe '#export?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(filter.export?(message)).to eq(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(filter.export?(message)).to eq(false) }
    end
  end
end
