# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:caller) { build(:consumer) }
  let(:sampler) { ::Karafka::Web.config.tracking.consumers.sampler }
  let(:type) { rand.to_s }
  let(:error) { nil }
  let(:event) do
    event = OpenStruct.new(type: type, error: error, caller: caller)
    event.payload = event
    event
  end

  before do
    sampler.jobs.clear
    sampler.windows.clear
  end

  describe '#on_error_occurred' do
    let(:error) { StandardError.new(-'This is an error') }

    before do
      listener.on_consumer_consume(event)
      listener.on_consumer_revoke(event)
      listener.on_consumer_shutting_down(event)
    end

    context 'when type is none of the consumer related' do
      let(:type) { 'librdkafka.error' }

      it { expect { listener.on_error_occurred(event) }.not_to raise_error }
    end

    context 'when type is consumer.consume.error' do
      let(:type) { 'consumer.consume.error' }

      it 'expect to remove the running job from tracked jobs' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).not_to include("#{caller.id}-consume")
      end

      it 'expect not to remove revoke job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-revoked")
      end

      it 'expect not to remove shutdown job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-shutdown")
      end
    end

    context 'when type is consumer.revoked.error' do
      let(:type) { 'consumer.revoked.error' }

      it 'expect not to remove the running job from tracked jobs' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-consume")
      end

      it 'expect to remove revoke job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).not_to include("#{caller.id}-revoked")
      end

      it 'expect not to remove shutdown job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-shutdown")
      end
    end

    context 'when type is consumer.shutdown.error' do
      let(:type) { 'consumer.shutdown.error' }

      it 'expect not to remove the running job from tracked jobs' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-consume")
      end

      it 'expect not to remove revoke job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-revoked")
      end

      it 'expect to remove shutdown job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).not_to include("#{caller.id}-shutdown")
      end
    end

    context 'when type is consumer.idle.error' do
      let(:type) { 'consumer.idle.error' }

      it 'expect not to remove the running job from tracked jobs' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-consume")
      end

      it 'expect not to remove revoke job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-revoked")
      end

      it 'expect not to remove shutdown job for same consumer' do
        listener.on_error_occurred(event)
        expect(sampler.jobs).to include("#{caller.id}-shutdown")
      end
    end
  end

  describe '#on_worker_processed' do
    before { event[:time] = 123.456 }

    it 'expect to track execution time in totals' do
      listener.on_worker_processed(event)
      expect(sampler.windows.m1[:processed_total_time]).to include(123.456)
    end
  end

  describe '#on_consumer_consume' do
    before { listener.on_consumer_consume(event) }

    it 'expect to increase batches count' do
      expect(sampler.counters[:batches]).to eq(1)
    end

    it 'expect to increase messages count' do
      expect(sampler.counters[:messages]).to eq(1)
    end

    it 'expect to register the job execution' do
      expect(sampler.jobs).not_to be_empty
    end

    it 'expect to have job details' do
      job = sampler.jobs.values.first

      expect(job.keys).to include(:started_at)
      expect(job[:topic]).to eq('test')
      expect(job[:partition]).to eq(0)
      expect(job[:first_offset]).to eq(0)
      expect(job[:last_offset]).to eq(1)
      expect(job[:processing_lag]).to eq(1_000)
      expect(job[:consumption_lag]).to eq(0)
      expect(job[:committed_offset]).to eq(0)
      expect(job[:messages]).to eq(1)
      expect(job[:consumer]).to eq(caller.class.to_s)
      expect(job[:consumer_group]).to eq(caller.topic.consumer_group.id)
      expect(job[:type]).to eq('consume')
      expect(job[:tags]).to eq(caller.tags)
    end
  end

  describe '#on_consumer_consumed' do
    before do
      listener.on_consumer_consume(event)
      listener.on_consumer_consumed(event)
    end

    it 'expect to remove job from running' do
      expect(sampler.jobs).to be_empty
    end
  end

  describe '#on_consumer_revoke' do
    before { listener.on_consumer_revoke(event) }

    it 'expect not to increase batches count' do
      expect(sampler.counters[:batches]).to eq(0)
    end

    it 'expect not to increase messages count' do
      expect(sampler.counters[:messages]).to eq(0)
    end

    it 'expect to register the job execution' do
      expect(sampler.jobs).not_to be_empty
    end

    it 'expect to have job details' do
      job = sampler.jobs.values.first

      expect(job.keys).to include(:started_at)
      expect(job[:topic]).to eq('test')
      expect(job[:partition]).to eq(0)
      expect(job[:first_offset]).to eq(0)
      expect(job[:last_offset]).to eq(1)
      expect(job[:processing_lag]).to eq(1_000)
      expect(job[:consumption_lag]).to eq(0)
      expect(job[:committed_offset]).to eq(0)
      expect(job[:messages]).to eq(1)
      expect(job[:consumer]).to eq(caller.class.to_s)
      expect(job[:consumer_group]).to eq(caller.topic.consumer_group.id)
      expect(job[:type]).to eq('revoked')
      expect(job[:tags]).to eq(caller.tags)
    end
  end

  describe '#on_consumer_revoked' do
    before do
      listener.on_consumer_revoke(event)
      listener.on_consumer_revoked(event)
    end

    it 'expect to remove job from running' do
      expect(sampler.jobs).to be_empty
    end
  end

  describe '#on_consumer_shutting_down' do
    before { listener.on_consumer_shutting_down(event) }

    it 'expect not to increase batches count' do
      expect(sampler.counters[:batches]).to eq(0)
    end

    it 'expect not to increase messages count' do
      expect(sampler.counters[:messages]).to eq(0)
    end

    it 'expect to register the job execution' do
      expect(sampler.jobs).not_to be_empty
    end

    it 'expect to have job details' do
      job = sampler.jobs.values.first

      expect(job.keys).to include(:started_at)
      expect(job[:topic]).to eq('test')
      expect(job[:partition]).to eq(0)
      expect(job[:first_offset]).to eq(0)
      expect(job[:last_offset]).to eq(1)
      expect(job[:processing_lag]).to eq(1_000)
      expect(job[:consumption_lag]).to eq(0)
      expect(job[:committed_offset]).to eq(0)
      expect(job[:messages]).to eq(1)
      expect(job[:consumer]).to eq(caller.class.to_s)
      expect(job[:consumer_group]).to eq(caller.topic.consumer_group.id)
      expect(job[:type]).to eq('shutdown')
      expect(job[:tags]).to eq(caller.tags)
    end
  end

  describe '#on_consumer_shutdown' do
    before do
      listener.on_consumer_shutting_down(event)
      listener.on_consumer_shutdown(event)
    end

    it 'expect to remove job from running' do
      expect(sampler.jobs).to be_empty
    end
  end
end
