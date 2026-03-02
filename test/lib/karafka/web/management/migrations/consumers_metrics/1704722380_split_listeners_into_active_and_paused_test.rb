# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::SplitListenersIntoActiveAndPaused
) do
  it { assert_equal("1.1.2", described_class.versions_until) }
  it { assert_equal(:consumers_metrics, described_class.type) }

  context "when migrating from 1.0.0" do
    let(:state) { Fixtures.consumers_metrics_json("v1.0.0") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to split listeners into active and standby" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          assert_equal({active: 2, standby: 0}, sample.last[:listeners])
        end
      end
    end
  end
end
