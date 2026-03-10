# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::RenameLagTotalToLagHybrid
) do
  it { assert_equal("1.2.1", described_class.versions_until) }
  it { assert_equal(:consumers_metrics, described_class.type) }

  context "when migrating from 1.2.0" do
    let(:state) { Fixtures.consumers_metrics_json("v1.2.0") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to move to lag_hybrid and no other keys from aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          assert(sample.last[:lag_hybrid].between?(0, 5))
          refute(sample.last.key?(:lag_total))
        end
      end
    end

    it "expect to move to lag_hybrid and no other keys from topics" do
      times.each do |key_name|
        state[:consumer_groups][key_name].each do |metrics|
          metric_group = metrics.last

          metric_group.each_value do |samples|
            samples.each_value do |sample|
              assert(sample[:lag_hybrid].between?(0, 5))
              refute(sample.key?(:lag_total))
            end
          end
        end
      end
    end
  end
end
