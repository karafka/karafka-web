# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:topic) do
    {
      name: 'topic1',
      partitions_cnt: 1,
      partitions: {
        0 => {
          id: 0,
          lag_stored: 10,
          lag_stored_d: 5,
          lag: 2,
          lag_d: 1,
          committed_offset: 100,
          committed_offset_fd: 0,
          stored_offset: 95,
          stored_offset_fd: 0,
          fetch_state: 'active',
          poll_state: 'active',
          poll_state_ch: 0,
          hi_offset: 1,
          hi_offset_fd: 1,
          lo_offset: 0,
          eof_offset: 0,
          ls_offset: 0,
          ls_offset_d: 0,
          ls_offset_fd: 0,
          transactional: false
        }
      }
    }
  end

  context 'when config is valid' do
    it { expect(contract.call(topic)).to be_success }
  end

  context 'when name is missing' do
    before { topic.delete(:name) }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when name is not a string' do
    before { topic[:name] = 123 }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when name is empty' do
    before { topic[:name] = '' }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when partitions is missing' do
    before { topic.delete(:partitions) }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when partitions is not a hash' do
    before { topic[:partitions] = 'not a hash' }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when partitions_cnt is missing' do
    before { topic.delete(:partitions_cnt) }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when partitions_cnt is not an integer' do
    before { topic[:partitions_cnt] = '5' }

    it { expect(contract.call(topic)).not_to be_success }
  end

  context 'when partitions_cnt is negative' do
    before { topic[:partitions_cnt] = -1 }

    it { expect(contract.call(topic)).not_to be_success }
  end
end
