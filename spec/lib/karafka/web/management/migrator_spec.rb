# frozen_string_literal: true

RSpec.describe_current do
  subject(:migrate) { described_class.new.call }

  let(:compatibility_error) { Karafka::Web::Errors::Management::IncompatibleSchemaError }
  let(:states_topic) { create_topic }
  let(:metrics_topic) { create_topic }
  let(:topics_config) { ::Karafka::Web.config.topics }

  let(:states_state) { Karafka::Web::Processing::Consumers::State.current! }
  let(:metrics_state) { Karafka::Web::Processing::Consumers::Metrics.current! }

  context 'when consumers state schema is newer than what we support' do
    before do
      topics_config.consumers.states = states_topic
      produce(states_topic, { schema_version: '999.99.9' }.to_json)
    end

    it { expect { migrate }.to raise_error(compatibility_error) }
  end

  context 'when consumers metrics schema is newer than what we support' do
    before do
      topics_config.consumers.metrics = metrics_topic
      produce(metrics_topic, { schema_version: '999.99.9' }.to_json)
    end

    it { expect { migrate }.to raise_error(compatibility_error) }
  end

  context 'when we start from empty states' do
    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.metrics = metrics_topic

      produce(states_topic, { schema_version: '0.0.0' }.to_json)
      produce(metrics_topic, { schema_version: '0.0.0' }.to_json)

      migrate
    end

    it 'expect to migrate consumers states to 1.2.0 with all needed details' do
      expect(states_state[:schema_version]).to eq('1.2.0')
      expect(states_state[:schema_state]).to eq('accepted')
      expect(states_state[:processes]).to eq({})
      expect(states_state[:dispatched_at]).to be < Time.now.to_f

      %i[
        batches messages retries dead busy enqueued processing workers processes rss listeners
        utilization errors lag_stored lag bytes_sent bytes_received
      ].each do |stats_key|
        expect(states_state[:stats][stats_key]).to eq(0)
      end
    end

    it 'expect to migrate consumers metrics to 1.1.0 with all needed details' do
      expect(metrics_state[:schema_version]).to eq('1.1.0')
      expect(states_state[:dispatched_at]).to be < Time.now.to_f

      %i[days hours minutes seconds].each do |stats_key|
        expect(metrics_state[:aggregated][stats_key]).to eq([])
        expect(metrics_state[:consumer_groups][stats_key]).to eq([])
      end
    end
  end
end
