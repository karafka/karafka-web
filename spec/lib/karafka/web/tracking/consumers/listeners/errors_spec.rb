# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:sampler) { ::Karafka::Web.config.tracking.consumers.sampler }
  let(:error) { StandardError.new(-'This is an error') }
  let(:event) do
    {
      type: 'error.occurred',
      error: error,
      caller: caller_ref
    }
  end

  let(:consumer_group) do
    instance_double(
      Karafka::Routing::ConsumerGroup,
      id: 'group1'
    )
  end

  let(:subscription_group) do
    instance_double(
      Karafka::Routing::SubscriptionGroup,
      id: 'sub1',
      consumer_group: consumer_group
    )
  end

  describe '#on_error_occurred' do
    let(:topic) do
      instance_double(
        Karafka::Routing::Topic,
        name: 'topic_name',
        consumer_group: consumer_group,
        subscription_group: subscription_group
      )
    end

    context 'when error message string is frozen' do
      let(:caller_ref) { nil }

      it 'expect to process it without problems' do
        expect { listener.on_error_occurred(event) }.not_to raise_error
      end
    end

    context 'when tracking error' do
      let(:caller_ref) { nil }

      it 'expect to include schema version 1.2.0' do
        listener.on_error_occurred(event)
        expect(sampler.errors.last[:schema_version]).to eq('1.2.0')
      end

      it 'expect to include a unique id' do
        listener.on_error_occurred(event)
        error_id = sampler.errors.last[:id]

        expect(error_id).to be_a(String)
        expect(error_id).not_to be_empty
        # UUID format validation
        expect(error_id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      end

      it 'expect each error to have a different id' do
        listener.on_error_occurred(event)
        first_id = sampler.errors.last[:id]

        listener.on_error_occurred(event)
        second_id = sampler.errors.last[:id]

        expect(first_id).not_to eq(second_id)
      end
    end

    context 'when caller is a consumer' do
      let(:messages_metadata) do
        instance_double(Karafka::Messages::BatchMetadata, first_offset: 5, last_offset: 10)
      end

      let(:messages) do
        instance_double(Karafka::Messages::Messages, metadata: messages_metadata)
      end

      let(:topic) do
        instance_double(
          Karafka::Routing::Topic,
          name: 'topic_name',
          consumer_group: consumer_group,
          subscription_group: subscription_group
        )
      end

      let(:coordinator) { instance_double(Karafka::Processing::Coordinator, seek_offset: 100) }
      let(:caller_ref) { Karafka::BaseConsumer.new }

      before do
        allow(caller_ref).to receive_messages(
          topic: topic,
          partition: 0,
          messages: messages,
          coordinator: coordinator,
          tags: %w[tag1]
        )
      end

      it 'expect to include consumer specific details' do
        listener.on_error_occurred(event)
        error_details = sampler.errors.last[:details]

        expect(error_details).to include(
          topic: 'topic_name',
          consumer_group: 'group1',
          subscription_group: 'sub1',
          partition: 0,
          first_offset: 5,
          last_offset: 10,
          committed_offset: 99,
          tags: %w[tag1]
        )
      end

      context 'when seek_offset is nil' do
        let(:coordinator) { instance_double(Karafka::Processing::Coordinator, seek_offset: nil) }

        it 'expect to set committed_offset to -1001' do
          listener.on_error_occurred(event)
          expect(sampler.errors.last[:details][:committed_offset]).to eq(-1001)
        end
      end

      context 'when Karafka is pro version' do
        let(:errors_tracker) { OpenStruct.new(trace_id: 'trace-123-abc') }

        before do
          allow(Karafka).to receive(:pro?).and_return(true)
          allow(caller_ref).to receive(:errors_tracker).and_return(errors_tracker)
        end

        it 'expect to include trace_id in details' do
          listener.on_error_occurred(event)
          error_details = sampler.errors.last[:details]

          expect(error_details).to include(trace_id: 'trace-123-abc')
        end
      end

      context 'when Karafka is not pro version' do
        before do
          allow(Karafka).to receive(:pro?).and_return(false)
        end

        it 'expect trace_id to be nil' do
          listener.on_error_occurred(event)
          error_details = sampler.errors.last[:details]

          expect(error_details).to include(trace_id: nil)
        end
      end
    end

    context 'when caller is a client' do
      let(:caller_ref) do
        Karafka::Connection::Client.new(
          subscription_group,
          nil
        )
      end

      it 'expect to include client specific details' do
        listener.on_error_occurred(event)
        error_details = sampler.errors.last[:details]

        expect(error_details).to include(
          consumer_group: 'group1',
          subscription_group: 'sub1',
          name: ''
        )
      end
    end

    context 'when caller is a listener' do
      before { allow(subscription_group).to receive(:topics).and_return([topic]) }

      let(:caller_ref) do
        Karafka::Connection::Listener.new(
          subscription_group,
          Karafka::Processing::JobsQueue.new,
          nil
        )
      end

      it 'expect to include listener specific details' do
        listener.on_error_occurred(event)
        error_details = sampler.errors.last[:details]

        expect(error_details).to include(
          consumer_group: 'group1',
          subscription_group: 'sub1'
        )
      end
    end

    context 'when caller is unknown' do
      let(:caller_ref) { Object.new }

      it 'expect to include empty details' do
        listener.on_error_occurred(event)
        expect(sampler.errors.last[:details]).to eq({})
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
      expect(sampler.counters[:retries]).to eq(1)
    end
  end
end
