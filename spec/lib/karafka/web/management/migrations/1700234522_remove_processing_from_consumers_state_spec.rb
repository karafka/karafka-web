# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::RemoveProcessingFromConsumersState do
  it { expect(described_class.versions_until).to eq('1.2.1') }
  it { expect(described_class.type).to eq(:consumers_state) }

  context 'when migrating from 1.1.0' do
    let(:state) { Fixtures.consumers_states_json('v1.1.0') }

    before { described_class.new.migrate(state) }

    it { expect(state[:stats].key?(:processing)).to eq(false) }
  end
end
