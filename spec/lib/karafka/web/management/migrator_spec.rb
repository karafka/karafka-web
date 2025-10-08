# frozen_string_literal: true

RSpec.describe_current do
  subject(:migrate) { described_class.new.call }

  let(:compatibility_error) { Karafka::Web::Errors::Management::IncompatibleSchemaError }
  let(:states_topic) { create_topic }
  let(:metrics_topic) { create_topic }
  let(:topics_config) { Karafka::Web.config.topics }

  let(:states_state) { Karafka::Web::Processing::Consumers::State.current! }
  let(:metrics_state) { Karafka::Web::Processing::Consumers::Metrics.current! }

  context 'when consumers state schema is newer than what we support' do
    before do
      topics_config.consumers.states.name = states_topic
      produce(states_topic, { schema_version: '999.99.9' }.to_json)
    end

    it { expect { migrate }.to raise_error(compatibility_error) }
  end

  context 'when consumers metrics schema is newer than what we support' do
    before do
      topics_config.consumers.metrics.name = metrics_topic
      produce(metrics_topic, { schema_version: '999.99.9' }.to_json)
    end

    it { expect { migrate }.to raise_error(compatibility_error) }
  end

  context 'when we start from empty states' do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      produce(states_topic, { schema_version: '0.0.0' }.to_json)
      produce(metrics_topic, { schema_version: '0.0.0' }.to_json)

      migrate
    end

    it 'expect to migrate consumers states to 1.4.0 with all needed details' do
      expect(states_state[:schema_version]).to eq('1.4.0')
      expect(states_state[:schema_state]).to eq('accepted')
      expect(states_state[:processes]).to eq({})
      expect(states_state[:dispatched_at]).to be < Time.now.to_f
      expect(states_state[:stats][:listeners]).to eq(active: 0, standby: 0)

      %i[
        batches jobs messages retries dead busy enqueued waiting workers processes rss
        utilization errors lag_hybrid bytes_sent bytes_received
      ].each do |stats_key|
        expect(states_state[:stats][stats_key]).to eq(0)
      end
    end

    it 'expect to migrate consumers metrics to 1.3.0 with all needed details' do
      expect(metrics_state[:schema_version]).to eq('1.3.0')
      expect(states_state[:dispatched_at]).to be < Time.now.to_f

      %i[days hours minutes seconds].each do |stats_key|
        expect(metrics_state[:aggregated][stats_key]).to eq([])
        expect(metrics_state[:consumer_groups][stats_key]).to eq([])
      end
    end
  end

  # The most current versions of fixtures should not diverge from migrated. If it does, fixtures
  # alias to current needs to point to the migrated state
  describe 'fixtures current versions' do
    context 'when checking consumers metrics current' do
      let(:current) { Fixtures.consumers_metrics_json }
      let(:migrated) { Karafka::Admin.read_topic(metrics_topic, 0, 1).first.payload }

      before do
        topics_config.consumers.metrics.name = metrics_topic
        produce(metrics_topic, current.to_json)
        migrate
      end

      it { expect(current.to_json).to eq(migrated.to_json) }
    end

    context 'when checking consumers states current' do
      let(:current) { Fixtures.consumers_states_json }
      let(:migrated) { Karafka::Admin.read_topic(states_topic, 0, 1).first.payload }

      before do
        topics_config.consumers.states.name = states_topic
        produce(states_topic, current.to_json)
        migrate
      end

      it { expect(current.to_json).to eq(migrated.to_json) }
    end
  end
end
