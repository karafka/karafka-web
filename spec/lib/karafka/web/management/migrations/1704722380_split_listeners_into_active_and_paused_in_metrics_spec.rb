# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::SplitListenersIntoActiveAndPausedInMetrics do
  it { expect(described_class.versions_until).to eq('1.1.2') }
  it { expect(described_class.type).to eq(:consumers_metrics) }

  context 'when migrating from 1.0.0' do
    let(:state) { Fixtures.consumers_metrics_json('v1.0.0') }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it 'expect to split listeners into active and standby' do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:listeners]).to eq(active: 2, standby: 0)
        end
      end
    end
  end
end
