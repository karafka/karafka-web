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

      assert_predicate(schema.call(recorded_errors.first), :success?)
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
end
