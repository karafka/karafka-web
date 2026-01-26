# frozen_string_literal: true

RSpec.describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::PopulateJobsMetrics
) do
  it { expect(described_class.versions_until).to eq("1.3.0") }
  it { expect(described_class.type).to eq(:consumers_metrics) }

  context "when migrating from 1.2.1" do
    let(:state) { Fixtures.consumers_metrics_json("v1.2.1") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to populate aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:jobs]).to eq(sample.last[:batches])
          expect(sample.last.key?(:jobs)).to be(true)
        end
      end
    end
  end
end
