# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::FillMissingReceivedAndSentBytes
) do
  it { assert_equal("1.1.0", described_class.versions_until) }
  it { assert_equal(:consumers_metrics, described_class.type) }

  context "when migrating from 1.0.0" do
    let(:state) { Fixtures.consumers_metrics_json("v1.0.0") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to add bytes_sent to all aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          assert_equal(0, sample.last[:bytes_sent])
        end
      end
    end

    it "expect to add bytes_received to all aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          assert_equal(0, sample.last[:bytes_received])
        end
      end
    end
  end
end
