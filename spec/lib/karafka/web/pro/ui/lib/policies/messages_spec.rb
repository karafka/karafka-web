# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:policy) { described_class.new }

  describe '#key?' do
    it { expect(policy.key?('irrelevant')).to be(true) }
  end

  describe '#headers?' do
    it { expect(policy.headers?('irrelevant')).to be(true) }
  end

  describe '#payload?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(policy.payload?(message)).to be(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(policy.payload?(message)).to be(false) }
    end
  end

  describe '#download?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(policy.download?(message)).to be(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(policy.download?(message)).to be(false) }
    end
  end

  describe '#export?' do
    context 'when encryption is off' do
      let(:message) { OpenStruct.new(headers: {}) }

      it { expect(policy.export?(message)).to be(true) }
    end

    context 'when encryption is on' do
      let(:message) { OpenStruct.new(headers: { 'encryption' => true }) }

      it { expect(policy.export?(message)).to be(false) }
    end
  end

  describe '#republish?' do
    it { expect(policy.republish?(nil)).to be(true) }
  end
end
