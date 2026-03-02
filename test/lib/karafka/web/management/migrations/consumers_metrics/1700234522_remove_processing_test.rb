# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::RemoveProcessing
) do
  it { assert_equal("1.1.1", described_class.versions_until) }
  it { assert_equal(:consumers_metrics, described_class.type) }

  context "when migrating from 1.0.0" do
    let(:state) { Fixtures.consumers_metrics_json("v1.0.0") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to add waiting to all aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          assert_equal(false, sample.last.key?(:processing))
        end
      end
    end
  end
end
