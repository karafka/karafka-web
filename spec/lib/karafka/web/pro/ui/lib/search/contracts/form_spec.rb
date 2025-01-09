# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:params) do
    {
      phrase: 'search phrase',
      limit: 10_000,
      matcher: 'Raw header includes',
      offset_type: 'latest',
      offset: 0,
      timestamp: ((Time.now.to_f + 30) * 1_000).to_i,
      partitions: %w[partition1 partition2]
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when phrase is invalid' do
    context 'when phrase is not a string' do
      before { params[:phrase] = 123 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when phrase is empty' do
      before { params[:phrase] = '' }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when limit is invalid' do
    context 'when limit is not an integer' do
      before { params[:limit] = 'not_an_integer' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when limit is less than 1' do
      before { params[:limit] = 0 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when limit is greater than 100_000' do
      before { params[:limit] = 100_001 }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when matcher is invalid' do
    context 'when matcher is not in the declared matchers' do
      before { params[:matcher] = 'InvalidMatcher' }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when offset_type is invalid' do
    context 'when offset_type is not a valid option' do
      before { params[:offset_type] = 'invalid_type' }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when offset is invalid' do
    context 'when offset is not an integer' do
      before { params[:offset] = 'not_an_integer' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when offset is negative' do
      before { params[:offset] = -1 }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when timestamp is invalid' do
    context 'when timestamp is not an integer' do
      before { params[:timestamp] = 'not_an_integer' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when timestamp is negative' do
      before { params[:timestamp] = -1 }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when timestamp is in the future' do
      before { params[:timestamp] = ((Time.now.to_f + 120) * 1_000).to_i }

      it { expect(contract.call(params)).not_to be_success }
    end
  end

  context 'when partitions is invalid' do
    context 'when partitions is not an array' do
      before { params[:partitions] = 'not_an_array' }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when partitions is an empty array' do
      before { params[:partitions] = [] }

      it { expect(contract.call(params)).not_to be_success }
    end

    context 'when partitions contains non-string elements' do
      before { params[:partitions] = [1, 2, 3] }

      it { expect(contract.call(params)).not_to be_success }
    end
  end
end
