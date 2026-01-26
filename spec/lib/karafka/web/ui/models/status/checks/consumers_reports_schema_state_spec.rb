# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:state_calculation) }
    it { expect(described_class.halted_details).to eq({}) }
  end

  describe "#call" do
    context "when schema state is compatible" do
      before do
        context.current_state = { schema_state: "compatible" }
      end

      it "returns success" do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.success?).to be(true)
      end
    end

    context "when schema state is incompatible" do
      before do
        context.current_state = { schema_state: "incompatible" }
      end

      it "returns failure" do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.success?).to be(false)
      end
    end

    context "when schema state is something else" do
      before do
        context.current_state = { schema_state: "unknown" }
      end

      it "returns failure" do
        result = check.call

        expect(result.status).to eq(:failure)
      end
    end
  end
end
