# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:sampler) { ::Karafka::Web.config.tracking.producers.sampler }

  let(:error) do
    error = StandardError.new
    error.set_backtrace(caller)
    error
  end

  let(:event) do
    Karafka::Core::Monitoring::Event.new(
      rand,
      producer_id: 'test_producer',
      type: 'test_type',
      error: error,
      payload: {
        topic: 'test_topic',
        partition: 1,
        offset: 123
      }
    )
  end

  before { sampler.clear }

  describe '#on_error_occurred' do
    let(:recorded_errors) { sampler.errors }

    before { listener.on_error_occurred(event) }

    it { expect(recorded_errors.size).to eq(1) }

    it 'expect the error to match the error contract' do
      schema = ::Karafka::Web::Tracking::Contracts::Error.new
      expect(schema.call(recorded_errors.first)).to be_success
    end
  end
end
