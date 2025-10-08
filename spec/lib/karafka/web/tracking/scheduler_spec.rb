# frozen_string_literal: true

RSpec.describe_current do
  subject(:scheduler) { described_class.new }

  let(:consumers_reporter) { Karafka::Web.config.tracking.consumers.reporter }
  let(:producers_reporter) { Karafka::Web.config.tracking.producers.reporter }

  before do
    allow(consumers_reporter).to receive(:report)
    allow(producers_reporter).to receive(:report)

    allow(scheduler).to receive(:sleep).and_raise(StandardError)
  end

  describe '#call' do
    before do
      allow(consumers_reporter).to receive(:active?).and_return(true)
      allow(producers_reporter).to receive(:active?).and_return(false)
    end

    it 'executes only active reporters' do
      expect { scheduler.send(:call) }.to raise_error(StandardError)

      expect(consumers_reporter).to have_received(:report).once
      expect(producers_reporter).not_to have_received(:report)
    end
  end
end
