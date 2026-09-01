# frozen_string_literal: true

describe_current do
  let(:aggregated) { described_class.call(state) }

  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before { Karafka::Web.config.topics.consumers.reports.name = reports_topic }

  context "when none of the processes are active" do
    it { assert_equal({}, aggregated) }
  end

  context "when there are active processes" do
    let(:cg) { "example_app6_app" }
    let(:topic) { "default" }

    before do
      produce(reports_topic, report.to_json)
      produce(reports_topic, report.to_json)
    end

    it "expect to preserve the consumer group => topics tree shape" do
      assert_equal(%w[example_app6_app], aggregated.keys)
      assert_equal(%w[default test2 visits], aggregated[cg][:topics].keys)
      assert_in_delta(2_690_818_656.575_513, aggregated[cg][:rebalanced_at])
    end

    it "expect each topic to be collapsed into an AggregatedTopic summary" do
      topic_stats = aggregated[cg][:topics][topic]

      assert_instance_of(Karafka::Web::Ui::Models::Health::AggregatedTopic, topic_stats)
      assert_equal(1, topic_stats.partitions_count)
      assert_equal(1, topic_stats.present_count)
      assert_equal(213_731_273, topic_stats.lag_hybrid)
      assert_equal(213_731_273, topic_stats.max_lag)
      assert_equal(0, topic_stats.max_lag_partition_id)
      assert_equal(:active, topic_stats.lso_risk_state)
      assert_equal(0, topic_stats.paused_count)
      assert_equal(0, topic_stats.no_data_count)
    end
  end
end
