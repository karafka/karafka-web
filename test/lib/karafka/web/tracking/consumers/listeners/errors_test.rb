# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }
  let(:error) { StandardError.new(-"This is an error") }
  let(:event) do
    {
      type: "error.occurred",
      error: error,
      caller: caller_ref
    }
  end

  let(:consumer_group) do
    stub(id: "group1")
  end

  let(:subscription_group) do
    stub(id: "sub1",
      consumer_group: consumer_group)
  end

  describe "#on_error_occurred" do
    let(:topic) do
      stub(name: "topic_name",
        consumer_group: consumer_group,
        subscription_group: subscription_group)
    end

    context "when error message string is frozen" do
      let(:caller_ref) { nil }

      it "expect to process it without problems" do
        listener.on_error_occurred(event)
      end
    end

    context "when tracking error" do
      let(:caller_ref) { nil }

      it "expect to include schema version 1.2.0" do
        listener.on_error_occurred(event)

        assert_equal("1.2.0", sampler.errors.last[:schema_version])
      end

      it "expect to include a unique id" do
        listener.on_error_occurred(event)
        error_id = sampler.errors.last[:id]

        assert_kind_of(String, error_id)
        refute_empty(error_id)
        # UUID format validation
        assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, error_id)
      end

      it "expect each error to have a different id" do
        listener.on_error_occurred(event)
        first_id = sampler.errors.last[:id]

        listener.on_error_occurred(event)
        second_id = sampler.errors.last[:id]

        refute_equal(second_id, first_id)
      end
    end

    context "when caller is a consumer" do
      let(:routing_consumer_group) do
        build(:routing_consumer_group, name: "group1")
      end

      let(:routing_subscription_group) do
        Struct.new(:id, :consumer_group).new("sub1", routing_consumer_group)
      end

      let(:routing_topic) do
        topic = build(
          :routing_topic,
          name: "topic_name",
          consumer_group: routing_consumer_group
        )
        topic.subscription_group = routing_subscription_group
        topic
      end

      let(:coordinator) do
        build(:processing_coordinator, topic: routing_topic, partition: 0, seek_offset: 100)
      end

      let(:batch_metadata) do
        Karafka::Messages::BatchMetadata.new(
          size: 10,
          first_offset: 5,
          last_offset: 10,
          deserializers: nil,
          partition: 0,
          topic: "topic_name",
          created_at: Time.now,
          scheduled_at: Time.now - 1,
          processed_at: Time.now
        )
      end

      let(:messages) do
        Struct.new(:size, :metadata).new(1, batch_metadata)
      end

      let(:caller_ref) do
        consumer = build(:consumer, coordinator: coordinator)
        consumer.messages = messages
        consumer.tags.add(:test, "tag1")
        consumer
      end

      it "expect to include consumer specific details" do
        listener.on_error_occurred(event)
        error_details = sampler.errors.last[:details]

        assert_includes(error_details, topic: "topic_name", consumer_group: "group1", subscription_group: "sub1", partition: 0, first_offset: 5, last_offset: 10, committed_offset: 99)

        assert_equal(["tag1"], error_details[:tags].to_a)
      end

      context "when seek_offset is nil" do
        let(:coordinator) do
          build(:processing_coordinator, topic: routing_topic, partition: 0, seek_offset: nil)
        end

        it "expect to set committed_offset to -1001" do
          listener.on_error_occurred(event)

          assert_equal(-1001, sampler.errors.last[:details][:committed_offset])
        end
      end

      context "when Karafka is pro version" do
        let(:errors_tracker) { Struct.new(:trace_id).new("trace-123-abc") }

        let(:caller_ref) do
          consumer = build(:consumer, coordinator: coordinator)
          consumer.messages = messages
          consumer.tags.add(:test, "tag1")
          # Define errors_tracker method for pro version testing
          tracker = errors_tracker
          consumer.define_singleton_method(:errors_tracker) { tracker }
          consumer
        end

        before do
          Karafka.stubs(:pro?).returns(true)
        end

        it "expect to include trace_id in details" do
          listener.on_error_occurred(event)
          error_details = sampler.errors.last[:details]

          assert_equal("trace-123-abc", error_details[:trace_id])
        end
      end

      context "when Karafka is not pro version" do
        before do
          Karafka.stubs(:pro?).returns(false)
        end

        it "expect trace_id to be nil" do
          listener.on_error_occurred(event)
          error_details = sampler.errors.last[:details]

          assert_nil(error_details[:trace_id])
        end
      end
    end

    context "when caller is a client" do
      let(:caller_ref) do
        Karafka::Connection::Client.new(
          subscription_group,
          nil
        )
      end

      it "expect to include client specific details" do
        listener.on_error_occurred(event)
        error_details = sampler.errors.last[:details]

        assert_includes(error_details, consumer_group: "group1", subscription_group: "sub1", name: "")
      end
    end

    context "when caller is a listener" do
      before { subscription_group.stubs(:topics).returns([topic]) }

      let(:caller_ref) do
        Karafka::Connection::Listener.new(
          subscription_group,
          Karafka::Processing::JobsQueue.new,
          nil
        )
      end

      it "expect to include listener specific details" do
        listener.on_error_occurred(event)
        error_details = sampler.errors.last[:details]

        assert_includes(error_details, consumer_group: "group1", subscription_group: "sub1")
      end
    end

    context "when caller is unknown" do
      let(:caller_ref) { Object.new }

      it "expect to include empty details" do
        listener.on_error_occurred(event)

        assert_equal({}, sampler.errors.last[:details])
      end
    end
  end

  describe "#on_dead_letter_queue_dispatched" do
    it "expect to increase the dlq counter" do
      listener.on_dead_letter_queue_dispatched(nil)

      assert_equal(1, sampler.counters[:dead])
    end
  end

  describe "#on_consumer_consuming_retry" do
    it "expect to increase the retry counter" do
      listener.on_consumer_consuming_retry(nil)

      assert_equal(1, sampler.counters[:retries])
    end
  end
end
