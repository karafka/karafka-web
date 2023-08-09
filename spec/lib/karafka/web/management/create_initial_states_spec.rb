# frozen_string_literal: true

RSpec.describe_current do
  subject(:create) { described_class.new.call }

  let(:consumers_states_topic) { create_topic }
  let(:consumers_metrics_topic) { create_topic }
  let(:consumers_state) { Karafka::Web::Processing::Consumers::State.current! }
  let(:consumers_metrics) { Karafka::Web::Processing::Consumers::Metrics.current! }

  before do
    Karafka::Web.config.topics.consumers.states = consumers_states_topic
    Karafka::Web.config.topics.consumers.metrics = consumers_metrics_topic
  end

  context 'when the consumers state already exists' do
    before { produce(consumers_states_topic, fixtures_file('consumers_state.json')) }

    it 'expect not to overwrite it' do
      create
      expect(consumers_state[:dispatched_at]).to eq(2_690_818_670.782_473)
    end
  end

  context 'when the consumers state is missing' do
    let(:initial_stats) do
      {
        batches: 0,
        messages: 0,
        retries: 0,
        dead: 0,
        busy: 0,
        enqueued: 0,
        processing: 0,
        workers: 0,
        processes: 0,
        rss: 0,
        listeners: 0,
        utilization: 0,
        lag_stored: 0,
        errors: 0
      }
    end

    it 'expect to create it with appropriate values' do
      create
      expect(consumers_state[:processes]).to be_empty
      expect(consumers_state[:stats]).to eq(initial_stats)
      expect(consumers_state[:dispatched_at]).not_to be_nil
      expect(consumers_state[:schema_state]).to eq('accepted')
      expect(consumers_state[:schema_version]).to eq('1.1.0')
    end
  end

  context 'when the consumers metrics already exists' do
    before { produce(consumers_metrics_topic, fixtures_file('consumers_metrics.json')) }

    it 'expect not to overwrite it' do
      create
      expect(consumers_metrics[:dispatched_at]).to eq(1_690_817_198.082_236)
    end
  end

  context 'when the consumers metrics is missing' do
    let(:initial_aggregated) do
      {
        days: [],
        hours: [],
        minutes: [],
        seconds: []
      }
    end

    let(:initial_consumer_groups) do
      {
        days: [],
        hours: [],
        minutes: [],
        seconds: []
      }
    end

    it 'expect to create it with appropriate values' do
      create
      expect(consumers_metrics[:aggregated]).to eq(initial_aggregated)
      expect(consumers_metrics[:consumer_groups]).to eq(initial_consumer_groups)
      expect(consumers_metrics[:schema_version]).to eq('1.0.0')
      expect(consumers_metrics[:dispatched_at]).not_to be_nil
    end
  end
end
