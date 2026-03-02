# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute_predicate(described_class, :independent?) }
    it { assert_equal(:state_calculation, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    context "when schema state is compatible" do
      before do
        context.current_state = { schema_state: "compatible" }
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_predicate(result, :success?)
      end
    end

    context "when schema state is incompatible" do
      before do
        context.current_state = { schema_state: "incompatible" }
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        refute_predicate(result, :success?)
      end
    end

    context "when schema state is something else" do
      before do
        context.current_state = { schema_state: "unknown" }
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
      end
    end
  end
end
