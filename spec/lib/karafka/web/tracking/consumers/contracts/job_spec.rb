# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:job) do
    {
      consumer: 'consumer1',
      consumer_group: 'consumer_group1',
      started_at: 1_624_301_554.123,
      topic: 'topic1',
      partition: 0,
      first_offset: 0,
      last_offset: 100,
      committed_offset: 50,
      type: 'consume',
      tags: Karafka::Core::Taggable::Tags.new,
      consumption_lag: 0,
      processing_lag: 0
    }
  end

  context 'when config is valid' do
    it { expect(contract.call(job)).to be_success }
  end

  context 'when consumer is missing' do
    before { job.delete(:consumer) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when consumer is not a string' do
    before { job[:consumer] = 123 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when consumer_group is missing' do
    before { job.delete(:consumer_group) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when consumer_group is not a string' do
    before { job[:consumer_group] = 123 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when started_at is missing' do
    before { job.delete(:started_at) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when started_at is not a float' do
    before { job[:started_at] = 'not a float' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when started_at is less than 0' do
    before { job[:started_at] = -1.0 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when topic is missing' do
    before { job.delete(:topic) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when topic is not a string' do
    before { job[:topic] = 123 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when partition is missing' do
    before { job.delete(:partition) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when partition is not an integer' do
    before { job[:partition] = 'not an integer' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when partition is less than 0' do
    before { job[:partition] = -1 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when first_offset is missing' do
    before { job.delete(:first_offset) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when first_offset is not an integer' do
    before { job[:first_offset] = 'not an integer' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when first_offset is less than 0 and not equal to -1001' do
    before { job[:first_offset] = -2 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when last_offset is missing' do
    before { job.delete(:last_offset) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when last_offset is not an integer' do
    before { job[:last_offset] = 'not an integer' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when last_offset is less than 0 and not equal to -1001' do
    before { job[:last_offset] = -2 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when committed_offset is missing' do
    before { job.delete(:committed_offset) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when committed_offset is not an integer' do
    before { job[:committed_offset] = 'not an integer' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when type is missing' do
    before { job.delete(:type) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when type is not a string' do
    before { job[:type] = 123 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when type is not within allowed types' do
    before { job[:type] = 'unknown_type' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when tags is missing' do
    before { job.delete(:tags) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when tags is not a Karafka::Core::Taggable::Tags' do
    before { job[:tags] = 123 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when consumption_lag is missing' do
    before { job.delete(:consumption_lag) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when consumption_lag is not an integer' do
    before { job[:consumption_lag] = 'not an integer' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when consumption_lag is less than 0 and not equal to -1' do
    before { job[:consumption_lag] = -2 }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when processing_lag is missing' do
    before { job.delete(:processing_lag) }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when processing_lag is not an integer' do
    before { job[:processing_lag] = 'not an integer' }

    it { expect(contract.call(job)).not_to be_success }
  end

  context 'when processing_lag is less than 0 and not equal to -1' do
    before { job[:processing_lag] = -2 }

    it { expect(contract.call(job)).not_to be_success }
  end
end
