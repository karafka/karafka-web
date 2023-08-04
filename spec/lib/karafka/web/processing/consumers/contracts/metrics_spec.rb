# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:metrics) do
    {
      dispatched_at: Time.now.to_f,
      schema_version: '1.0.0',
      aggregated: {},
      consumer_groups: {}
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(metrics)).to be_success
    end
  end

  context 'when dispatched_at is negative' do
    before { metrics[:dispatched_at] = -1 }

    it { expect(contract.call(metrics)).not_to be_success }
  end

  context 'when dispatched_at is not a number' do
    before { metrics[:dispatched_at] = 'test' }

    it { expect(contract.call(metrics)).not_to be_success }
  end

  context 'when schema_version is empty' do
    before { metrics[:schema_version] = '' }

    it { expect(contract.call(metrics)).not_to be_success }
  end

  context 'when schema_version is not a string' do
    before { metrics[:schema_version] = 123 }

    it { expect(contract.call(metrics)).not_to be_success }
  end

  context 'when aggregated metrics exist but are not valid' do
    before { metrics[:aggregated] = { days: [[1, { batches: -2 }]] } }

    it { expect { contract.call(metrics) }.to raise_error(Karafka::Web::Errors::ContractError) }
  end

  context 'when consumer_groups metrics exist but are not valid' do
    before { metrics[:consumer_groups] = { days: [[1, { 'name' => { 'topic' => {} } }]] } }

    it { expect { contract.call(metrics) }.to raise_error(Karafka::Web::Errors::ContractError) }
  end
end
