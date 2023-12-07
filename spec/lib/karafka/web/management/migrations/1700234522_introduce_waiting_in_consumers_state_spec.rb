# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::IntroduceWaitingInConsumersState do
  it { expect(described_class.versions_until).to eq('1.2.1') }
  it { expect(described_class.type).to eq(:consumers_state) }

  context 'when migrating from 1.1.0' do
    let(:state) { Fixtures.json('consumers_state_v1.1.0') }

    before { described_class.new.migrate(state) }

    it { expect(state[:stats][:waiting]).to eq(0) }
  end
end
