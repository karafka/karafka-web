# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:topic) do
    {
      name: 'topic1',
      partitions: {
        0 => {
          id: 0,
          lag_stored: 10,
          lag_stored_d: 5,
          committed_offset: 100,
          stored_offset: 95
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
end
