# frozen_string_literal: true

RSpec.describe(
  Karafka::Web::Management::Migrations::ConsumersStates::RenameLagTotalToLagHybrid
) do
  it { expect(described_class.versions_until).to eq('1.3.1') }
  it { expect(described_class.type).to eq(:consumers_states) }

  context 'when migrating from 1.3.0' do
    let(:state) { Fixtures.consumers_states_json('v1.3.0') }

    before { described_class.new.migrate(state) }

    it { expect(state[:stats][:lag_hybrid]).to eq(0) }
    it { expect(state[:stats].key?(:lag_total)).to be(false) }
  end
end
