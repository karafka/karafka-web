# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::PopulateJobsMetrics
) do
  it { assert_equal("1.3.0", described_class.versions_until) }
  it { assert_equal(:consumers_metrics, described_class.type) }

  context "when migrating from 1.2.1" do
    let(:state) { Fixtures.consumers_metrics_json("v1.2.1") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to populate aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          assert_equal(sample.last[:batches], sample.last[:jobs])
          assert(sample.last.key?(:jobs))
        end
      end
    end
  end
end
