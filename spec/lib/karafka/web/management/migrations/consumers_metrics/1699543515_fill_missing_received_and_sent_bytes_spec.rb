# frozen_string_literal: true

RSpec.describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::FillMissingReceivedAndSentBytes
) do
  it { expect(described_class.versions_until).to eq("1.1.0") }
  it { expect(described_class.type).to eq(:consumers_metrics) }

  context "when migrating from 1.0.0" do
    let(:state) { Fixtures.consumers_metrics_json("v1.0.0") }
    let(:times) { %i[days hours minutes seconds] }

    before { described_class.new.migrate(state) }

    it "expect to add bytes_sent to all aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:bytes_sent]).to eq(0)
        end
      end
    end

    it "expect to add bytes_received to all aggregated" do
      times.each do |key_name|
        state[:aggregated][key_name].each do |sample|
          expect(sample.last[:bytes_received]).to eq(0)
        end
      end
    end
  end
end
