# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:params) do
    {
      schema_version: '1.0.0',
      dispatched_at: Time.now.to_f,
      schema_state: 'compatible',
      stats: {
        batches: 10,
        messages: 100,
        retries: 5,
        dead: 2,
        errors: 3,
        busy: 4,
        enqueued: 6,
        workers: 5,
        processes: 2,
        rss: 512.45,
        listeners: {
          active: 3,
          standby: 0
        },
        utilization: 70.2,
        lag_hybrid: 50,
        lag: 10
      },
      processes: {}
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(params)).to be_success
    end
  end

  context 'when schema_version is empty' do
    before { params[:schema_version] = '' }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when schema_version is not a string' do
    before { params[:schema_version] = 123 }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when dispatched_at is negative' do
    before { params[:dispatched_at] = -1 }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when dispatched_at is not a number' do
    before { params[:dispatched_at] = 'test' }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when stats is not a hash' do
    before { params[:stats] = 'not a hash' }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when processes are missing' do
    before { params.delete(:processes) }

    it { expect(contract.call(params)).not_to be_success }
  end

  context 'when process is not valid' do
    before { params[:processes] = { 'test' => {} } }

    it { expect { contract.call(params) }.to raise_error(Karafka::Web::Errors::ContractError) }
  end

  context 'when schema state is not one of the accepted' do
    before { params[:schema_state] = 'na' }

    it { expect(contract.call(params)).not_to be_success }
  end
end
