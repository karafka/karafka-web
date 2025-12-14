# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:consumer_group) do
    {
      id: 'example_app_karafka_web',
      subscription_groups: {
        'c81e728d9d4c_1' => {
          id: 'c81e728d9d4c_1',
          instance_id: false,
          state: {
            state: 'up',
            join_state: 'steady',
            stateage: 90_002,
            rebalance_age: 90_000,
            rebalance_cnt: 1,
            rebalance_reason: 'Metadata for subscribed topic(s) has changed',
            poll_age: 12
          },
          topics: {
            'karafka_consumers_reports' => {
              name: 'karafka_consumers_reports',
              partitions_cnt: 1,
              partitions: {
                0 => {
                  lag_stored: 0,
                  lag_stored_d: 0,
                  committed_offset: 18,
                  committed_offset_fd: 0,
                  stored_offset: 18,
                  stored_offset_fd: 0,
                  fetch_state: 'active',
                  id: 0,
                  poll_state: 'active',
                  poll_state_ch: 0,
                  hi_offset: 10,
                  hi_offset_fd: 10,
                  lag_d: 10,
                  lag: 10,
                  lo_offset: 0,
                  eof_offset: 0,
                  ls_offset: 0,
                  ls_offset_d: 0,
                  ls_offset_fd: 0,
                  transactional: false
                }
              }
            }
          }
        }
      }
    }
  end

  context 'when config is valid' do
    it { expect(contract.call(consumer_group)).to be_success }
  end

  context 'when id is missing' do
    before { consumer_group.delete(:id) }

    it { expect(contract.call(consumer_group)).not_to be_success }
  end

  context 'when id is empty' do
    before { consumer_group[:id] = '' }

    it { expect(contract.call(consumer_group)).not_to be_success }
  end

  context 'when id is not a string' do
    before { consumer_group[:id] = 123 }

    it { expect(contract.call(consumer_group)).not_to be_success }
  end

  context 'when subscription_groups is missing' do
    before { consumer_group.delete(:subscription_groups) }

    it { expect(contract.call(consumer_group)).not_to be_success }
  end

  context 'when subscription_groups is not a hash' do
    before { consumer_group[:subscription_groups] = 'not a hash' }

    it { expect(contract.call(consumer_group)).not_to be_success }
  end

  context 'when subscription_group does not have an id' do
    let(:expected_error) { Karafka::Web::Errors::ContractError }

    before { consumer_group[:subscription_groups]['c81e728d9d4c_1'].delete(:id) }

    it { expect { contract.call(consumer_group) }.to raise_error(expected_error) }
  end
end
