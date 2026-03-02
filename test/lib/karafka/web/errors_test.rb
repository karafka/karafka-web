# frozen_string_literal: true

describe_current do
  describe "BaseError" do
    let(:error) { described_class::BaseError }

    it { assert_operator(error, :<, StandardError) }
  end

  describe "ContractError" do
    let(:error) { described_class::ContractError }

    it { assert_operator(error, :<, described_class::BaseError) }
  end

  describe "LateSetupError" do
    let(:error) { described_class::LateSetupError }

    it { assert_operator(error, :<, described_class::BaseError) }
  end

  context "when in Processing namespace" do
    describe "MissingConsumersStateError" do
      let(:error) { described_class::Processing::MissingConsumersStateError }

      it { assert_operator(error, :<, described_class::BaseError) }
    end

    describe "MissingConsumersMetricsError" do
      let(:error) { described_class::Processing::MissingConsumersMetricsError }

      it { assert_operator(error, :<, described_class::BaseError) }
    end
  end

  context "when in Ui namespace" do
    describe "NotFoundError" do
      let(:error) { described_class::Ui::NotFoundError }

      it { assert_operator(error, :<, described_class::BaseError) }
    end

    describe "ProOnlyError" do
      let(:error) { described_class::Ui::ProOnlyError }

      it { assert_operator(error, :<, described_class::BaseError) }
    end

    describe "ForbiddenError" do
      let(:error) { described_class::Ui::ForbiddenError }

      it { assert_operator(error, :<, described_class::BaseError) }
    end
  end
end
