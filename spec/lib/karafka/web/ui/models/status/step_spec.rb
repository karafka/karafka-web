# frozen_string_literal: true

RSpec.describe_current do
  subject(:step) { described_class.new(status, details) }

  let(:status) { :success }
  let(:details) { { key: 'value' } }

  describe '#success?' do
    context 'when status is :success' do
      let(:status) { :success }

      it { expect(step.success?).to be(true) }
    end

    context 'when status is :warning' do
      let(:status) { :warning }

      it { expect(step.success?).to be(true) }
    end

    context 'when status is :failure' do
      let(:status) { :failure }

      it { expect(step.success?).to be(false) }
    end

    context 'when status is :halted' do
      let(:status) { :halted }

      it { expect(step.success?).to be(false) }
    end
  end

  describe '#partial_namespace' do
    context 'when status is :success' do
      let(:status) { :success }

      it { expect(step.partial_namespace).to eq('successes') }
    end

    context 'when status is :warning' do
      let(:status) { :warning }

      it { expect(step.partial_namespace).to eq('warnings') }
    end

    context 'when status is :failure' do
      let(:status) { :failure }

      it { expect(step.partial_namespace).to eq('failures') }
    end

    context 'when status is :halted' do
      let(:status) { :halted }

      it { expect(step.partial_namespace).to eq('failures') }
    end

    context 'when status is unknown' do
      let(:status) { :unknown }

      it 'raises an error' do
        expect { step.partial_namespace }.to raise_error(Karafka::Errors::UnsupportedCaseError)
      end
    end
  end

  describe '#to_s' do
    context 'when status is :success' do
      let(:status) { :success }

      it { expect(step.to_s).to eq('success') }
    end

    context 'when status is :failure' do
      let(:status) { :failure }

      it { expect(step.to_s).to eq('failure') }
    end
  end

  describe '#details' do
    it { expect(step.details).to eq({ key: 'value' }) }

    context 'when details is nil' do
      let(:details) { nil }

      it { expect(step.details).to be_nil }
    end
  end
end
