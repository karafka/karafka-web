# frozen_string_literal: true

RSpec.describe_current do
  describe 'BaseError' do
    subject(:error) { described_class::BaseError }

    specify { expect(error).to be < StandardError }
  end

  describe 'ContractError' do
    subject(:error) { described_class::ContractError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'LateSetupError' do
    subject(:error) { described_class::LateSetupError }

    specify { expect(error).to be < described_class::BaseError }
  end

  context 'when in Processing namespace' do
    describe 'MissingConsumersStateError' do
      subject(:error) { described_class::Processing::MissingConsumersStateError }

      specify { expect(error).to be < described_class::BaseError }
    end

    describe 'MissingConsumersMetricsError' do
      subject(:error) { described_class::Processing::MissingConsumersMetricsError }

      specify { expect(error).to be < described_class::BaseError }
    end

    describe 'IncompatibleSchemaError' do
      subject(:error) { described_class::Processing::IncompatibleSchemaError }

      specify { expect(error).to be < described_class::BaseError }
    end
  end

  context 'when in Ui namespace' do
    describe 'NotFoundError' do
      subject(:error) { described_class::Ui::NotFoundError }

      specify { expect(error).to be < described_class::BaseError }
    end

    describe 'ProOnlyError' do
      subject(:error) { described_class::Ui::ProOnlyError }

      specify { expect(error).to be < described_class::BaseError }
    end
  end
end
