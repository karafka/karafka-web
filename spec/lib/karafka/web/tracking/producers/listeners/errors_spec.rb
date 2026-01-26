# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

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

    it { expect(recorded_errors.size).to eq(1) }

    it "expect the error to match the error contract" do
      schema = Karafka::Web::Tracking::Contracts::Error.new
      expect(schema.call(recorded_errors.first)).to be_success
    end

    it "expect to include schema version 1.2.0" do
      expect(recorded_errors.first[:schema_version]).to eq("1.2.0")
    end

    it "expect to include a unique id" do
      error_id = recorded_errors.first[:id]

      expect(error_id).to be_a(String)
      expect(error_id).not_to be_empty
      # UUID format validation
      expect(error_id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end

    it "expect each error to have a different id" do
      first_id = recorded_errors.first[:id]

      listener.on_error_occurred(event)
      second_id = sampler.errors.last[:id]

      expect(first_id).not_to eq(second_id)
    end
  end
end
