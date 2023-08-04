# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:process_params) do
    {
      dispatched_at: Time.now.to_f,
      offset: 5
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(process_params)).to be_success
    end
  end

  context 'when dispatched_at is negative' do
    before { process_params[:dispatched_at] = -1 }

    it { expect(contract.call(process_params)).not_to be_success }
  end

  context 'when dispatched_at is not a number' do
    before { process_params[:dispatched_at] = 'test' }

    it { expect(contract.call(process_params)).not_to be_success }
  end

  context 'when offset is negative' do
    before { process_params[:offset] = -1 }

    it { expect(contract.call(process_params)).not_to be_success }
  end

  context 'when offset is not a number' do
    before { process_params[:offset] = 'test' }

    it { expect(contract.call(process_params)).not_to be_success }
  end

  context 'when offset is a float' do
    before { process_params[:offset] = 1.2 }

    it { expect(contract.call(process_params)).not_to be_success }
  end
end
