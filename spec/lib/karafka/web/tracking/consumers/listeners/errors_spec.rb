# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:sampler) { ::Karafka::Web.config.tracking.consumers.sampler }
  let(:error) { StandardError.new(-'This is an error') }
  let(:event) do
    {
      type: 'error.occurred',
      error: error
    }
  end

  describe '#on_error_occurred' do
    context 'when error message string is frozen' do
      it 'expect to process it without problems' do
        expect { listener.on_error_occurred(event) }.not_to raise_error
      end
    end
  end

  describe '#on_dead_letter_queue_dispatched' do
    it 'expect to increase the dlq counter' do
      listener.on_dead_letter_queue_dispatched(nil)

      expect(sampler.counters[:dead]).to eq(1)
    end
  end

  describe '#on_consumer_consuming_retry' do
    it 'expect to increase the retry counter' do
      listener.on_consumer_consuming_retry(nil)

      expect(sampler.counters[:dead]).to eq(1)
    end
  end
end
