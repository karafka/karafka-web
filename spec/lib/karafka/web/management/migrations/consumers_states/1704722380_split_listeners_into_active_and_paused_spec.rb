# frozen_string_literal: true

RSpec.describe(
  Karafka::Web::Management::Migrations::ConsumersStates::SplitListenersIntoActiveAndPaused
) do
  it { expect(described_class.versions_until).to eq('1.2.2') }
  it { expect(described_class.type).to eq(:consumers_states) }

  context 'when migrating from 1.1.0' do
    let(:state) { Fixtures.consumers_states_json('v1.1.0') }

    before { described_class.new.migrate(state) }

    it { expect(state[:stats][:listeners]).to eq(active: 4, standby: 0) }
  end
end
