# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:sampler) { Karafka::Web.config.tracking.producers.sampler }

  let(:error) do
    error = StandardError.new
    error.set_backtrace(caller)
    error
  end

  let(:event) do
    Karafka::Core::Monitoring::Event.new(
      rand,
      producer_id: "test_producer",
      type: "test_type",
      error: error,
      payload: {
        topic: "test_topic",
        partition: 1,
        offset: 123
      }
    )
  end

  before { sampler.clear }

  describe "#on_error_occurred" do
    let(:recorded_errors) { sampler.errors }

    before { listener.on_error_occurred(event) }

    it { assert_equal(1, recorded_errors.size) }

    it "expect the error to match the error contract" do
      schema = Karafka::Web::Tracking::Contracts::Error.new

      assert(schema.call(recorded_errors.first).success?)
    end

    it "expect to include schema version 1.2.0" do
      assert_equal("1.2.0", recorded_errors.first[:schema_version])
    end

    it "expect to include a unique id" do
      error_id = recorded_errors.first[:id]

      assert_kind_of(String, error_id)
      refute_empty(error_id)
      # UUID format validation
      assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, error_id)
    end

    it "expect each error to have a different id" do
      first_id = recorded_errors.first[:id]

      listener.on_error_occurred(event)
      second_id = sampler.errors.last[:id]

      refute_equal(second_id, first_id)
    end
  end

  describe "#on_error_occurred with a librdkafka dispatch error" do
    let(:status) { Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED }
    let(:latency) { 12_345 }
    let(:broker_id) { 1 }

    let(:delivery_report) do
      Rdkafka::Producer::DeliveryReport.new(
        2,
        100,
        "test_topic",
        1,
        nil,
        status: status,
        latency: latency,
        broker_id: broker_id
      )
    end

    let(:event) do
      Karafka::Core::Monitoring::Event.new(
        rand,
        producer_id: "test_producer",
        type: "librdkafka.dispatch_error",
        error: error,
        topic: "test_topic",
        partition: 2,
        offset: 100,
        delivery_report: delivery_report
      )
    end

    let(:details) { sampler.errors.last[:details] }

    before { listener.on_error_occurred(event) }

    it "expect to include the delivery outcome in the details" do
      expected = {
        topic: "test_topic",
        partition: 2,
        offset: 100,
        delivery_status: "possibly persisted",
        latency_ms: 12.35,
        broker_id: 1
      }

      assert_equal(expected, details)
    end

    it "expect the error to match the error contract" do
      schema = Karafka::Web::Tracking::Contracts::Error.new

      assert(schema.call(sampler.errors.last).success?)
    end

    context "when the message was not persisted" do
      let(:status) { Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_NOT_PERSISTED }

      it { assert_equal("not persisted", details[:delivery_status]) }
    end

    context "when the message was persisted" do
      let(:status) { Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_PERSISTED }

      it { assert_equal("persisted", details[:delivery_status]) }
    end

    context "when status, latency and broker are not known" do
      let(:status) { nil }
      let(:latency) { nil }
      let(:broker_id) { nil }

      it "expect to report them as nil" do
        assert_nil(details[:delivery_status])
        assert_nil(details[:latency_ms])
        assert_nil(details[:broker_id])
      end
    end

    context "when the delivery report does not carry the delivery outcome" do
      let(:delivery_report) { Struct.new(:partition, :offset).new(2, 100) }

      it "expect to report only the topic, partition and offset" do
        assert_equal({ topic: "test_topic", partition: 2, offset: 100 }, details)
      end
    end
  end
end
