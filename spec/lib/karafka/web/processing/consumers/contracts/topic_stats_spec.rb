# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:topic_stats) do
    {
      lag_stored: 10,
      lag: 5,
      offset_hi: 3
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(topic_stats)).to be_success
    end
  end

  context 'when lag_stored is not a number' do
    before { topic_stats[:lag_stored] = 'test' }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context 'when lag_stored is missing' do
    before { topic_stats.delete(:lag_stored) }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context 'when lag is not a number' do
    before { topic_stats[:lag] = 'test' }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context 'when lag is missing' do
    before { topic_stats.delete(:lag) }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context 'when offset_hi is not a number' do
    before { topic_stats[:offset_hi] = 'test' }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context 'when offset_hi is missing' do
    before { topic_stats.delete(:offset_hi) }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end
end
