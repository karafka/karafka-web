# frozen_string_literal: true

describe_current do
  let(:step) { described_class.new(status, details) }

  let(:status) { :success }
  let(:details) { { key: "value" } }

  describe "#success?" do
    context "when status is :success" do
      let(:status) { :success }

      it { assert(step.success?) }
    end

    context "when status is :warning" do
      let(:status) { :warning }

      it { assert(step.success?) }
    end

    context "when status is :failure" do
      let(:status) { :failure }

      it { refute(step.success?) }
    end

    context "when status is :halted" do
      let(:status) { :halted }

      it { refute(step.success?) }
    end
  end

  describe "#partial_namespace" do
    context "when status is :success" do
      let(:status) { :success }

      it { assert_equal("successes", step.partial_namespace) }
    end

    context "when status is :warning" do
      let(:status) { :warning }

      it { assert_equal("warnings", step.partial_namespace) }
    end

    context "when status is :failure" do
      let(:status) { :failure }

      it { assert_equal("failures", step.partial_namespace) }
    end

    context "when status is :halted" do
      let(:status) { :halted }

      it { assert_equal("failures", step.partial_namespace) }
    end

    context "when status is unknown" do
      let(:status) { :unknown }

      it "raises an error" do
        assert_raises(Karafka::Errors::UnsupportedCaseError) { step.partial_namespace }
      end
    end
  end

  describe "#to_s" do
    context "when status is :success" do
      let(:status) { :success }

      it { assert_equal("success", step.to_s) }
    end

    context "when status is :failure" do
      let(:status) { :failure }

      it { assert_equal("failure", step.to_s) }
    end
  end

  describe "#details" do
    it { assert_equal({ key: "value" }, step.details) }

    context "when details is nil" do
      let(:details) { nil }

      it { assert_nil(step.details) }
    end
  end
end
