# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  describe '#on_statistics_emitted' do
    let(:reporter) { ::Karafka::Web.config.tracking.producers.reporter }

    before { allow(reporter).to receive(:report) }

    it 'expect to run report via reporter' do
      listener.on_statistics_emitted({})
      expect(reporter).to have_received(:report)
    end
  end
end
