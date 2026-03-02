# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:max_lag) { (Karafka::Web.config.tracking.interval * 2) / 1_000 }

  describe "DSL configuration" do
    it { refute_predicate(described_class, :independent?) }
    it { assert_equal(:live_reporting, described_class.dependency) }

    it "returns halted details with max_lag" do
      details = described_class.halted_details

      assert_equal(0, details[:lag])
      assert_equal(max_lag, details[:max_lag])
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

        assert_equal(:success, result.status)
        assert_operator(result.details[:lag], :<, max_lag)
        assert_equal(max_lag, result.details[:max_lag])
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

        assert_equal(:failure, result.status)
        assert_operator(result.details[:lag], :>, max_lag)
      end
    end
  end
end
