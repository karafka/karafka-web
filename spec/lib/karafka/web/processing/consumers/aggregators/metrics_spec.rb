# frozen_string_literal: true

RSpec.describe_current do
  subject(:metrics_aggregator) { described_class.new }

  let(:reports_topic) { Karafka::Web.config.topics.consumers.reports = create_topic }
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics = create_topic }
  let(:states_topic) { Karafka::Web.config.topics.consumers.states = create_topic }
  let(:schema_manager) { Karafka::Web::Processing::Consumers::SchemaManager.new }
  let(:state_aggregator) do
    Karafka::Web::Processing::Consumers::Aggregators::State.new(schema_manager)
  end

  before do
    reports_topic
    metrics_topic
    states_topic
  end

  context 'when there are no initial metrics' do
    let(:expected_error) { Karafka::Web::Errors::Processing::MissingConsumersMetricsError }

    it { expect { metrics_aggregator.to_h }.to raise_error(expected_error)  }
  end

  context 'when there are initial metrics but no other data' do
    before { Karafka::Web::Management::CreateInitialStates.new.call }

    it 'expect to have basic empty stats' do
      hashed = metrics_aggregator.to_h

      expect(hashed[:aggregated]).to eq(days: [], hours: [], minutes: [], seconds: [])
      expect(hashed[:consumer_groups]).to eq(days: [], hours: [], minutes: [], seconds: [])
      expect(hashed[:schema_version]).to eq('1.0.0')
      expect(hashed.key?(:dispatched_at)).to eq(true)
    end
  end

  context 'when we have data from a multi-topic, multi-partition setup' do
    let(:process1_report) do
      data = Fixtures.json('multi_partition_reports/process_1')
      data[:dispatched_at] = Time.now.to_f
      data
    end

    let(:process2_report) do
      data = Fixtures.json('multi_partition_reports/process_2')
      data[:dispatched_at] = Time.now.to_f
      data
    end

    before do
      Karafka::Web::Management::CreateInitialStates.new.call

      [process1_report, process2_report].each_with_index do |report, index|
        state_aggregator.add(report, index)
        metrics_aggregator.add_report(report)
        metrics_aggregator.add_stats(state_aggregator.stats)
      end
    end

    it 'expected to compute multi-process states correctly for all the topics' do
      topics1 = metrics_aggregator.to_h[:consumer_groups][:seconds][0][1][:example_app_app]
      topics2 = metrics_aggregator.to_h[:consumer_groups][:seconds][0][1][:example_app_karafka_web]

      expect(topics1[:visits][:lag_stored]).to eq(5)
      expect(topics1[:visits][:lag]).to eq(5)
      expect(topics1[:visits][:pace]).to eq(271_066)
      expect(topics1[:visits][:ls_offset_fd]).to eq(5_000)

      expect(topics1[:default][:lag_stored]).to eq(0)
      expect(topics1[:default][:lag]).to eq(15)
      expect(topics1[:default][:pace]).to eq(813_204)
      expect(topics1[:default][:ls_offset_fd]).to eq(0)

      expect(topics2[:karafka_consumers_reports][:lag_stored]).to eq(0)
      expect(topics2[:karafka_consumers_reports][:lag]).to eq(0)
      expect(topics2[:karafka_consumers_reports][:pace]).to eq(28_972)
      expect(topics2[:karafka_consumers_reports][:ls_offset_fd]).to eq(0)
    end
  end
end
