# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::RenameLagTotalToLagHybridInMetrics do
  it { expect(described_class.versions_until).to eq('1.2.1') }
  it { expect(described_class.type).to eq(:consumers_metrics) }

  context 'when migrating from 1.2.0' do
    let(:state) { Fixtures.consumers_metrics_json('v1.1.2') }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it 'expect to move to lag_hybrid and no other keys' do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:lag_hybrid]).to be_between(0, 5)
          expect(sample.last.key?(:lag_total)).to eq(false)
        end
      end
    end
  end
end
