# frozen_string_literal: true

RSpec.describe_current do
  subject(:historicals) { described_class.new(state) }

  context 'when stats are missing' do
    let(:state) { {} }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  context 'when dispatched_at is missing' do
    let(:state) { { stats: {} } }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  context 'when historicals are missing' do
    let(:state) { { stats: {}, dispatched_at: Time.now.to_f } }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  context 'when historicals and stats are empty' do
    let(:state) { { stats: {}, dispatched_at: Time.now.to_f, historicals: {} } }

    it { expect(historicals.to_h).to eq({}) }
  end
end
