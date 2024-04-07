# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:valid_kafka_config) do
    {
      brokers: %w[localhost:9092],
      client_id: 'test'
    }
  end

  let(:valid_params) do
    {
      commanding: {
        active: true,
        pause_timeout: 30,
        max_wait_time: 100,
        kafka: valid_kafka_config,
        consumer_group: 'valid_consumer_group'
      }
    }
  end

  context 'with valid parameters' do
    it 'is successful' do
      expect(contract.call(valid_params)).to be_success
    end
  end

  context 'with invalid parameters' do
    context 'when active is not a boolean' do
      it 'expect to fail' do
        invalid_params = valid_params.merge(commanding: { active: 'yes' })
        expect(contract.call(invalid_params)).not_to be_success
      end
    end

    context 'when pause_timeout is not a positive integer' do
      it 'expect to fail' do
        invalid_params = valid_params.merge(commanding: { pause_timeout: -5 })
        expect(contract.call(invalid_params)).not_to be_success
      end
    end

    context 'when max_wait_time is not a positive integer' do
      it 'expect to fail' do
        invalid_params = valid_params.merge(commanding: { max_wait_time: 0 })
        expect(contract.call(invalid_params)).not_to be_success
      end
    end

    context 'when kafka config is not a hash' do
      it 'expect to fail' do
        invalid_params = valid_params.merge(commanding: { kafka: 'string' })
        expect(contract.call(invalid_params)).not_to be_success
      end
    end

    context 'when consumer_group does not match the topic regexp' do
      it 'expect to fail' do
        invalid_params = valid_params.merge(commanding: { consumer_group: 'invalid consumer group' })
        expect(contract.call(invalid_params)).not_to be_success
      end
    end

    context 'when kafka keys are not symbols' do
      it 'expect to fail' do
        invalid_kafka_config = { 'brokers' => %w[localhost:9092], 'client_id' => 'test' }
        invalid_params = valid_params.merge(commanding: { kafka: invalid_kafka_config })
        expect(contract.call(invalid_params)).not_to be_success
      end
    end
  end
end
