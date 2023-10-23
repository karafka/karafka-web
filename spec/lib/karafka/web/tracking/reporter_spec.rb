# frozen_string_literal: true

RSpec.describe_current do
  subject(:reporter) { described_class.new }

  describe '#active?' do
    context 'when producer is not yet created' do
      before { allow(Karafka).to receive(:producer).and_return(nil) }

      it { expect(reporter.active?).to eq(false) }
    end

    context 'when producer is not active' do
      before { allow(Karafka.producer.status).to receive(:active?).and_return(false) }

      it { expect(reporter.active?).to eq(false) }
    end

    context 'when producer exists and is active' do
      it { expect(reporter.active?).to eq(true) }
    end
  end
end
