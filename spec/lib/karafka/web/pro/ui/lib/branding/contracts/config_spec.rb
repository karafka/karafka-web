# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:params) do
    {
      ui: {
        branding: {
          type: :warning,
          label: 'Valid Label',
          notice: 'Valid Notice'
        }
      }
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when branding type is invalid' do
    before { params[:ui][:branding][:type] = 'invalid_type' }

    it 'is not valid' do
      expect(contract.call(params)).not_to be_success
    end
  end

  context 'when label is nil' do
    before { params[:ui][:branding][:label] = nil }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when label is false' do
    before { params[:ui][:branding][:label] = false }

    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when label is an empty string' do
    before { params[:ui][:branding][:label] = '' }

    it 'is not valid' do
      expect(contract.call(params)).not_to be_success
    end
  end

  context 'when notice is nil' do
    before { params[:ui][:branding][:notice] = nil }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when notice is false' do
    before { params[:ui][:branding][:notice] = false }

    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when notice is an empty string' do
    before { params[:ui][:branding][:notice] = '' }

    it 'is not valid' do
      expect(contract.call(params)).not_to be_success
    end
  end
end
