# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:params) do
    {
      ui: {
        policies: {
          messages: -> {},
          requests: -> {}
        }
      }
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when messages is nil' do
    before { params[:ui][:policies][:messages] = nil }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when requests is nil' do
    before { params[:ui][:policies][:requests] = nil }

    it { expect(contract.call(params)).not_to be_success }
  end
end
