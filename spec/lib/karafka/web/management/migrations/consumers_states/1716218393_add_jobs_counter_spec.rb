# frozen_string_literal: true

RSpec.describe(
  Karafka::Web::Management::Migrations::ConsumersStates::AddJobsCounter
) do
  it { expect(described_class.versions_until).to eq('1.4.0') }
  it { expect(described_class.type).to eq(:consumers_states) }

  context 'when migrating from 1.3.1' do
    let(:state) { Fixtures.consumers_states_json('v1.4.0') }

    before { described_class.new.migrate(state) }

    it { expect(state[:stats][:jobs]).to eq(16351) }
    it { expect(state[:stats].key?(:jobs)).to eq(true) }
  end
end
