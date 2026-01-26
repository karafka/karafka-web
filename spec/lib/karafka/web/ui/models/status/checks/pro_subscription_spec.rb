# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { expect(described_class.independent?).to be(true) }
    it { expect(described_class.dependency).to be_nil }
  end

  describe "#call" do
    context "when Karafka Pro is enabled" do
      before { allow(Karafka).to receive(:pro?).and_return(true) }

      it "returns success" do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.success?).to be(true)
      end
    end

    context "when Karafka Pro is not enabled" do
      before { allow(Karafka).to receive(:pro?).and_return(false) }

      it "returns warning" do
        result = check.call

        expect(result.status).to eq(:warning)
        expect(result.success?).to be(true)
      end
    end
  end
end
