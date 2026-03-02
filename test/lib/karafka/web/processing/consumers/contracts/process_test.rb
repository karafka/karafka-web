# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }

  let(:valid_params) do
    {
      dispatched_at: Time.now.to_f,
      offset: 12_345
    }
  end

  context "when all values are valid" do
    it "is valid" do
      assert_predicate(contract.call(valid_params), :success?)
    end
  end

  context "when validating dispatched_at" do
    context "when dispatched_at is missing" do
      before { valid_params.delete(:dispatched_at) }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when dispatched_at is negative" do
      before { valid_params[:dispatched_at] = -1 }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when dispatched_at is zero" do
      before { valid_params[:dispatched_at] = 0 }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when dispatched_at is not a number" do
      before { valid_params[:dispatched_at] = "test" }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when dispatched_at is nil" do
      before { valid_params[:dispatched_at] = nil }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when dispatched_at is a valid float" do
      before { valid_params[:dispatched_at] = 1_234_567_890.123 }

      it { assert_predicate(contract.call(valid_params), :success?) }
    end

    context "when dispatched_at is a valid integer" do
      before { valid_params[:dispatched_at] = 1_234_567_890 }

      it { assert_predicate(contract.call(valid_params), :success?) }
    end
  end

  context "when validating offset" do
    context "when offset is missing" do
      before { valid_params.delete(:offset) }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when offset is negative" do
      before { valid_params[:offset] = -1 }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when offset is zero" do
      before { valid_params[:offset] = 0 }

      it { assert_predicate(contract.call(valid_params), :success?) }
    end

    context "when offset is not an integer" do
      before { valid_params[:offset] = 123.45 }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when offset is a string" do
      before { valid_params[:offset] = "123" }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when offset is nil" do
      before { valid_params[:offset] = nil }

      it { refute_predicate(contract.call(valid_params), :success?) }
    end

    context "when offset is a large valid integer" do
      before { valid_params[:offset] = 999_999_999 }

      it { assert_predicate(contract.call(valid_params), :success?) }
    end
  end

  context "when both fields are invalid" do
    before do
      valid_params[:dispatched_at] = -1
      valid_params[:offset] = -1
    end

    it "fails validation" do
      result = contract.call(valid_params)
      refute_predicate(result, :success?)
      assert_includes(result.errors[:dispatched_at], "is invalid")
      assert_includes(result.errors[:offset], "is invalid")
    end
  end
end
