# frozen_string_literal: true

describe_current do
  include described_class

  describe "#status_badge" do
    let(:result) { status_badge(status) }

    context "when status is initialized, supervising, or running" do
      %w[
        initialized
        supervising
        running
      ].each do |valid_status|
        let(:status) { valid_status }

        it "returns badge-success" do
          assert_equal("badge-success", result)
        end
      end
    end

    context "when status is quieting" do
      let(:status) { "quieting" }

      it "returns badge-warning" do
        assert_equal("badge-warning", result)
      end
    end

    context "when status is quiet or stopping" do
      %w[
        quiet
        stopping
      ].each do |warning_status|
        let(:status) { warning_status }

        it "returns badge-warning" do
          assert_equal("badge-warning", result)
        end
      end
    end

    context "when status is stopped or terminated" do
      %w[
        stopped
        terminated
      ].each do |danger_status|
        let(:status) { danger_status }

        it "returns badge-error" do
          assert_equal("badge-error", result)
        end
      end
    end

    context "when status is unsupported" do
      let(:status) { "unsupported_status" }

      it "raises an UnsupportedCaseError" do
        assert_raises(Karafka::Errors::UnsupportedCaseError) { result }
      end
    end
  end

  describe "#lag_trend_badge" do
    let(:result) { lag_trend_badge(trend) }

    context "when trend is negative" do
      let(:trend) { -1 }

      it "returns badge-success" do
        assert_equal("badge-success", result)
      end
    end

    context "when trend is positive" do
      let(:trend) { 1 }

      it "returns badge-warning" do
        assert_equal("badge-warning", result)
      end
    end

    context "when trend is zero" do
      let(:trend) { 0 }

      it "returns badge-secondary" do
        assert_equal("badge-secondary", result)
      end
    end
  end

  describe "#kafka_state_badge" do
    let(:result) { kafka_state_badge(state) }

    context "when state is up, active, or steady" do
      %w[
        up
        active
        steady
      ].each do |positive_state|
        let(:state) { positive_state }

        it "returns badge-success" do
          assert_equal("badge-success", result)
        end
      end
    end

    context "when state is any other value" do
      let(:state) { "down" }

      it "returns badge-warning" do
        assert_equal("badge-warning", result)
      end
    end
  end
end
