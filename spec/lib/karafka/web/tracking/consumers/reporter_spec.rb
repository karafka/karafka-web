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

    context 'when producer exists but karafka is not even initializing' do
      before { allow(Karafka::App).to receive(:initializing?).and_return(true) }

      it { expect(reporter.active?).to eq(false) }
    end

    context 'when producer exists but karafka is not initialized' do
      before do
        allow(Karafka::App).to receive(:initializing?).and_return(false)
        allow(Karafka::App).to receive(:initialized?).and_return(true)
      end

      it { expect(reporter.active?).to eq(false) }
    end

    context 'when producer exists and is active and server is running' do
      before do
        allow(Karafka::App).to receive(:initializing?).and_return(false)
        allow(Karafka::App).to receive(:initialized?).and_return(false)
      end

      it { expect(reporter.active?).to eq(true) }
    end
  end
end
