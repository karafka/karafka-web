# frozen_string_literal: true

RSpec.describe_current do
  subject(:tracker) { described_class.new(existing) }

  let(:existing) { {} }

  context 'when there is no existing data' do
    it { expect(tracker.to_h).to eq({ days: [], hours: [], minutes: [], seconds: [] }) }
  end

  context 'when there is existing data' do
    let(:metrics) { Fixtures.consumers_metrics_json }
    let(:existing) { metrics.fetch(:aggregated) }

    it { expect(tracker.to_h[:days]).to eq(existing[:days]) }
    it { expect(tracker.to_h[:hours]).to eq(existing[:hours]) }
    it { expect(tracker.to_h[:minutes]).to eq(existing[:minutes]) }
    it { expect(tracker.to_h[:seconds]).to eq(existing[:seconds]) }
  end

  context 'when adding multiple metrics for the same time window' do
    before do
      tracker.add({ a: 1 }, 1)
      tracker.add({ a: 2 }, 1.01)
      tracker.add({ a: 3 }, 1_000_000)
      tracker.add({ a: 4 }, 1_000_000.01)
    end

    it 'expect to only keep the oldest one after materialization in a time window' do
      expect(tracker.to_h[:days]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
      expect(tracker.to_h[:hours]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
      expect(tracker.to_h[:minutes]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
      expect(tracker.to_h[:seconds]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
    end
  end
end
