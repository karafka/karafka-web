# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:caller) { build(:consumer) }
  let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }
  let(:type) { rand.to_s }
  let(:error) { nil }
  let(:event) do
    event = Struct.new(:type, :error, :caller, :payload, :time).new(type, error, caller, nil, nil)
    event.payload = event
    event
  end

  before do
    sampler.jobs.clear
    sampler.windows.clear
  end

  describe "#on_error_occurred" do
    let(:error) { StandardError.new(-"This is an error") }

    before do
      listener.on_consumer_consume(event)
      listener.on_consumer_revoke(event)
      listener.on_consumer_eof(event)
      listener.on_consumer_shutting_down(event)
    end

    context "when type is none of the consumer related" do
      let(:type) { "librdkafka.error" }

      it { listener.on_error_occurred(event) }
    end

    context "when type is consumer.consume.error" do
      let(:type) { "consumer.consume.error" }

      it "expect to remove the running job from tracked jobs" do
        listener.on_error_occurred(event)

        refute_includes(sampler.jobs, "#{caller.id}-consume")
      end

      it "expect not to remove revoke job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-revoked")
      end

      it "expect not to remove shutdown job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-shutdown")
      end
    end

    context "when type is consumer.revoked.error" do
      let(:type) { "consumer.revoked.error" }

      it "expect not to remove the running job from tracked jobs" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-consume")
      end

      it "expect to remove revoke job for same consumer" do
        listener.on_error_occurred(event)

        refute_includes(sampler.jobs, "#{caller.id}-revoked")
      end

      it "expect not to remove shutdown job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-shutdown")
      end
    end

    context "when type is consumer.shutdown.error" do
      let(:type) { "consumer.shutdown.error" }

      it "expect not to remove the running job from tracked jobs" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-consume")
      end

      it "expect not to remove revoke job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-revoked")
      end

      it "expect to remove shutdown job for same consumer" do
        listener.on_error_occurred(event)

        refute_includes(sampler.jobs, "#{caller.id}-shutdown")
      end
    end

    context "when type is consumer.idle.error" do
      let(:type) { "consumer.idle.error" }

      it "expect not to remove the running job from tracked jobs" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-consume")
      end

      it "expect not to remove revoke job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-revoked")
      end

      it "expect not to remove shutdown job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-shutdown")
      end
    end

    context "when type is consumer.eofed.error" do
      let(:type) { "consumer.eofed.error" }

      it "expect not to remove the running job from tracked jobs" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-consume")
      end

      it "expect not to remove revoke job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-revoked")
      end

      it "expect not to remove shutdown job for same consumer" do
        listener.on_error_occurred(event)

        assert_includes(sampler.jobs, "#{caller.id}-shutdown")
      end
    end
  end

  describe "#on_worker_processed" do
    before { event.time = 123.456 }

    it "expect to track execution time in totals" do
      listener.on_worker_processed(event)

      assert_includes(sampler.windows.m1[:processed_total_time], 123.456)
    end
  end

  describe "#on_consumer_consume" do
    before { listener.on_consumer_consume(event) }

    it "expect to increase batches count" do
      assert_equal(1, sampler.counters[:batches])
    end

    it "expect to increase messages count" do
      assert_equal(1, sampler.counters[:messages])
    end

    it "expect to register the job execution" do
      refute_empty(sampler.jobs)
    end

    it "expect to have job details" do
      job = sampler.jobs.values.first

      assert_includes(job.keys, :updated_at)
      assert_equal("test", job[:topic])
      assert_equal(0, job[:partition])
      assert_equal(0, job[:first_offset])
      assert_equal(1, job[:last_offset])
      assert_equal(1_000, job[:processing_lag])
      assert_equal(0, job[:consumption_lag])
      assert_equal(0, job[:committed_offset])
      assert_equal(1, job[:messages])
      assert_equal(caller.class.to_s, job[:consumer])
      assert_equal(caller.topic.consumer_group.id, job[:consumer_group])
      assert_equal("consume", job[:type])
      assert_equal(caller.tags, job[:tags])
    end
  end

  describe "#on_consumer_consumed" do
    before do
      listener.on_consumer_consume(event)
      listener.on_consumer_consumed(event)
    end

    it "expect to remove job from running" do
      assert_empty(sampler.jobs)
    end
  end

  describe "#on_consumer_eof" do
    before { listener.on_consumer_eof(event) }

    it "expect not to increase batches count" do
      assert_equal(0, sampler.counters[:batches])
    end

    it "expect not to increase messages count" do
      assert_equal(0, sampler.counters[:messages])
    end

    it "expect to register the job execution" do
      refute_empty(sampler.jobs)
    end

    it "expect to have job details" do
      job = sampler.jobs.values.first

      assert_includes(job.keys, :updated_at)
      assert_equal("test", job[:topic])
      assert_equal(0, job[:partition])
      assert_equal(0, job[:first_offset])
      assert_equal(1, job[:last_offset])
      # CI hiccups can cause this to drift a bit
      assert_in_delta(1_000, job[:processing_lag], 10)

      assert_equal(0, job[:consumption_lag])
      assert_equal(0, job[:committed_offset])
      assert_equal(1, job[:messages])
      assert_equal(caller.class.to_s, job[:consumer])
      assert_equal(caller.topic.consumer_group.id, job[:consumer_group])
      assert_equal("eofed", job[:type])
      assert_equal(caller.tags, job[:tags])
    end
  end

  describe "#on_consumer_eofed" do
    before do
      listener.on_consumer_eof(event)
      listener.on_consumer_eofed(event)
    end

    it "expect to remove job from running" do
      assert_empty(sampler.jobs)
    end
  end

  describe "#on_consumer_revoke" do
    before { listener.on_consumer_revoke(event) }

    it "expect not to increase batches count" do
      assert_equal(0, sampler.counters[:batches])
    end

    it "expect not to increase messages count" do
      assert_equal(0, sampler.counters[:messages])
    end

    it "expect to register the job execution" do
      refute_empty(sampler.jobs)
    end

    it "expect to have job details" do
      job = sampler.jobs.values.first

      assert_includes(job.keys, :updated_at)
      assert_equal("test", job[:topic])
      assert_equal(0, job[:partition])
      assert_equal(0, job[:first_offset])
      assert_equal(1, job[:last_offset])
      assert_equal(1_000, job[:processing_lag])
      assert_equal(0, job[:consumption_lag])
      assert_equal(0, job[:committed_offset])
      assert_equal(1, job[:messages])
      assert_equal(caller.class.to_s, job[:consumer])
      assert_equal(caller.topic.consumer_group.id, job[:consumer_group])
      assert_equal("revoked", job[:type])
      assert_equal(caller.tags, job[:tags])
    end
  end

  describe "#on_consumer_revoked" do
    before do
      listener.on_consumer_revoke(event)
      listener.on_consumer_revoked(event)
    end

    it "expect to remove job from running" do
      assert_empty(sampler.jobs)
    end
  end

  describe "#on_consumer_shutting_down" do
    before { listener.on_consumer_shutting_down(event) }

    it "expect not to increase batches count" do
      assert_equal(0, sampler.counters[:batches])
    end

    it "expect not to increase messages count" do
      assert_equal(0, sampler.counters[:messages])
    end

    it "expect to register the job execution" do
      refute_empty(sampler.jobs)
    end

    it "expect to have job details" do
      job = sampler.jobs.values.first

      assert_includes(job.keys, :updated_at)
      assert_equal("test", job[:topic])
      assert_equal(0, job[:partition])
      assert_equal(0, job[:first_offset])
      assert_equal(1, job[:last_offset])
      assert_equal(1_000, job[:processing_lag])
      assert_equal(0, job[:consumption_lag])
      assert_equal(0, job[:committed_offset])
      assert_equal(1, job[:messages])
      assert_equal(caller.class.to_s, job[:consumer])
      assert_equal(caller.topic.consumer_group.id, job[:consumer_group])
      assert_equal("shutdown", job[:type])
      assert_equal(caller.tags, job[:tags])
    end
  end

  describe "#on_consumer_shutdown" do
    before do
      listener.on_consumer_shutting_down(event)
      listener.on_consumer_shutdown(event)
    end

    it "expect to remove job from running" do
      assert_empty(sampler.jobs)
    end
  end
end
