# frozen_string_literal: true

RSpec.describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::IntroduceLagTotal
) do
  it { expect(described_class.versions_until).to eq('1.2.0') }
  it { expect(described_class.type).to eq(:consumers_metrics) }

  context 'when migrating from 1.0.0' do
    let(:state) { Fixtures.consumers_metrics_json('v1.0.0') }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it 'expect to introduce lag_total based on lag_stored and remove other lags from aggregated' do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:lag_total]).to be_between(0, 5)
          expect(sample.last.key?(:lag)).to be(false)
          expect(sample.last.key?(:lag_stored)).to be(false)
        end
      end
    end

    it 'expect to introduce lag_total based on lag_stored and remove other lags from topics' do
      times.each do |key_name|
        state[:consumer_groups][key_name].each do |metrics|
          metric_group = metrics.last

          metric_group.each_value do |samples|
            samples.each_value do |sample|
              expect(sample[:lag_total]).to be_between(0, 5)
              expect(sample.key?(:lag)).to be(false)
              expect(sample.key?(:lag_stored)).to be(false)
            end
          end
        end
      end
    end
  end

  context 'when migrating from 1.1.2' do
    let(:state) { Fixtures.consumers_metrics_json('v1.1.2') }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it 'expect to introduce lag_total based on lag_stored and remove other lags' do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:lag_total]).to be_between(0, 5)
          expect(sample.last.key?(:lag)).to be(false)
          expect(sample.last.key?(:lag_stored)).to be(false)
        end
      end
    end

    it 'expect to introduce lag_total based on lag_stored and remove other lags from topics' do
      times.each do |key_name|
        state[:consumer_groups][key_name].each do |metrics|
          metric_group = metrics.last

          metric_group.each_value do |samples|
            samples.each_value do |sample|
              expect(sample[:lag_total]).to be_between(0, 5)
              expect(sample.key?(:lag)).to be(false)
              expect(sample.key?(:lag_stored)).to be(false)
            end
          end
        end
      end
    end
  end
end
