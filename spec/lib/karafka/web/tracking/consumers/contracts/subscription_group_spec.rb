# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:subscription_group) do
    {
      id: 'subscription_group1',
      topics: {
        'topic1' => {
          name: 'topic1',
          partitions: {
            0 => {
              id: 0,
              lag_stored: 10,
              lag_stored_d: 5,
              lag: 0,
              lag_d: 0,
              committed_offset: 100,
              stored_offset: 95,
              hi_offset: 2,
              lo_offset: 0,
              eof_offset: 0,
              ls_offset: 0,
              ls_offset_d: 0,
              ls_offset_fd: 0,
              fetch_state: 'active',
              poll_state: 'active'
            }
          }
        }
      },
      state: {
        state: 'up',
        join_state: 'steady',
        stateage: 90_002,
        rebalance_age: 90_000,
        rebalance_cnt: 1,
        rebalance_reason: 'Metadata for subscribed topic(s) has changed'
      }
    }
  end

  context 'when config is valid' do
    it { expect(contract.call(subscription_group)).to be_success }
  end

  context 'when id is missing' do
    before { subscription_group.delete(:id) }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end

  context 'when id is not a string' do
    before { subscription_group[:id] = 123 }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end

  context 'when id is empty' do
    before { subscription_group[:id] = '' }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end

  context 'when topics is missing' do
    before { subscription_group.delete(:topics) }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end

  context 'when topics is not a hash' do
    before { subscription_group[:topics] = 'not a hash' }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end

  context 'when state is missing' do
    before { subscription_group.delete(:state) }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end

  context 'when state is not a hash' do
    before { subscription_group[:state] = 'not a hash' }

    it { expect(contract.call(subscription_group)).not_to be_success }
  end
end
