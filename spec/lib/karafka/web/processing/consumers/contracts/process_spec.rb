# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:valid_params) do
    {
      dispatched_at: Time.now.to_f,
      offset: 12_345
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(valid_params)).to be_success
    end
  end

  context 'when validating dispatched_at' do
    context 'when dispatched_at is missing' do
      before { valid_params.delete(:dispatched_at) }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when dispatched_at is negative' do
      before { valid_params[:dispatched_at] = -1 }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when dispatched_at is zero' do
      before { valid_params[:dispatched_at] = 0 }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when dispatched_at is not a number' do
      before { valid_params[:dispatched_at] = 'test' }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when dispatched_at is nil' do
      before { valid_params[:dispatched_at] = nil }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when dispatched_at is a valid float' do
      before { valid_params[:dispatched_at] = 1_234_567_890.123 }

      it { expect(contract.call(valid_params)).to be_success }
    end

    context 'when dispatched_at is a valid integer' do
      before { valid_params[:dispatched_at] = 1_234_567_890 }

      it { expect(contract.call(valid_params)).to be_success }
    end
  end

  context 'when validating offset' do
    context 'when offset is missing' do
      before { valid_params.delete(:offset) }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when offset is negative' do
      before { valid_params[:offset] = -1 }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when offset is zero' do
      before { valid_params[:offset] = 0 }

      it { expect(contract.call(valid_params)).to be_success }
    end

    context 'when offset is not an integer' do
      before { valid_params[:offset] = 123.45 }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when offset is a string' do
      before { valid_params[:offset] = '123' }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when offset is nil' do
      before { valid_params[:offset] = nil }

      it { expect(contract.call(valid_params)).not_to be_success }
    end

    context 'when offset is a large valid integer' do
      before { valid_params[:offset] = 999_999_999 }

      it { expect(contract.call(valid_params)).to be_success }
    end
  end

  context 'when both fields are invalid' do
    before do
      valid_params[:dispatched_at] = -1
      valid_params[:offset] = -1
    end

    it 'fails validation' do
      result = contract.call(valid_params)
      expect(result).not_to be_success
      expect(result.errors[:dispatched_at]).to include('is invalid')
      expect(result.errors[:offset]).to include('is invalid')
    end
  end
end
