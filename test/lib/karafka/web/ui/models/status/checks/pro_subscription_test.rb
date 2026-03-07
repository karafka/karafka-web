# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { assert(described_class.independent?) }
    it { assert_nil(described_class.dependency) }
  end

  describe "#call" do
    context "when Karafka Pro is enabled" do
      before { Karafka.stubs(:pro?).returns(true) }

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert(result.success?)
      end
    end

    context "when Karafka Pro is not enabled" do
      before { Karafka.stubs(:pro?).returns(false) }

      it "returns warning" do
        result = check.call

        assert_equal(:warning, result.status)
        assert(result.success?)
      end
    end
  end
end
