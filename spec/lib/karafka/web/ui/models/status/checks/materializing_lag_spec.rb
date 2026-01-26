# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:max_lag) { (Karafka::Web.config.tracking.interval * 2) / 1_000 }

  describe "DSL configuration" do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:live_reporting) }

    it "returns halted details with max_lag" do
      details = described_class.halted_details

      expect(details[:lag]).to eq(0)
      expect(details[:max_lag]).to eq(max_lag)
    end
  end

  describe "#call" do
    context "when lag is within acceptable range" do
      let(:current_state) do
        Struct.new(:dispatched_at).new(Time.now.to_f - 1)
      end

      before do
        context.current_state = current_state
      end

      it "returns success" do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details[:lag]).to be < max_lag
        expect(result.details[:max_lag]).to eq(max_lag)
      end
    end

    context "when lag exceeds acceptable range" do
      let(:current_state) do
        Struct.new(:dispatched_at).new(Time.now.to_f - (max_lag + 5))
      end

      before do
        context.current_state = current_state
      end

      it "returns failure" do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.details[:lag]).to be > max_lag
      end
    end
  end
end
