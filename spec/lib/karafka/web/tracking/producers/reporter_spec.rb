# frozen_string_literal: true

RSpec.describe_current do
  subject(:reporter) { described_class.new }

  let(:producer) { WaterDrop::Producer.new }
  let(:sampler) { ::Karafka::Web.config.tracking.producers.sampler }
  let(:errors_topic) { SecureRandom.uuid }
  let(:valid_error) do
    {
      schema_version: '1.0.0',
      type: 'librdkafka.dispatch_error',
      error_class: 'StandardError',
      error_message: 'Raised',
      backtrace: 'lib/file.rb',
      details: {},
      occurred_at: Time.now.to_f,
      process: { name: 'my-process' }
    }
  end

  before do
    Karafka::Web.config.topics.errors = errors_topic
    allow(Karafka).to receive(:producer).and_return(producer)
    allow(producer.status).to receive(:active?).and_return(true)
    allow(Karafka.producer).to receive(:produce_many_sync)
    allow(Karafka.producer).to receive(:produce_many_async)
  end

  context 'when there is nothing to report' do
    it 'expect not to dispatch any messages' do
      reporter.report

      expect(::Karafka.producer).not_to have_received(:produce_many_sync)
      expect(::Karafka.producer).not_to have_received(:produce_many_async)
    end
  end

  context 'when there is a report but it is not yet time to dispatch due to previous dispatch' do
    before do
      reporter.report
      sampler.errors << valid_error
    end

    it 'expect not to dispatch any messages yet' do
      reporter.report

      expect(::Karafka.producer).not_to have_received(:produce_many_sync)
      expect(::Karafka.producer).not_to have_received(:produce_many_async)
    end
  end

  context 'when we have error to report and it is time' do
    context 'when errot data does not comply with the expected schema' do
      before { sampler.errors << {} }

      it do
        expect { reporter.report }.to raise_error(Karafka::Web::Errors::ContractError)
      end
    end

    context 'when there is less than 25 of errors' do
      before { sampler.errors << valid_error }

      it 'expect to dispatch via async' do
        reporter.report

        expect(producer)
          .to have_received(:produce_many_async)
          .with([{ key: 'my-process', payload: valid_error.to_json, topic: errors_topic }])
      end
    end

    context 'when there is more than 25 errors' do
      let(:dispatch) do
        Array.new(26) do
          { key: 'my-process', payload: valid_error.to_json, topic: errors_topic }
        end
      end

      before { 26.times { sampler.errors << valid_error } }

      it 'expect to dispatch via sync' do
        reporter.report

        expect(producer)
          .to have_received(:produce_many_sync)
          .with(dispatch)
      end
    end

    context 'when dispatch is done' do
      before do
        sampler.errors << valid_error
        reporter.report
      end

      it 'expect to clear the dispatcher errors accumulator' do
        expect(sampler.errors).to be_empty
      end
    end
  end
end
