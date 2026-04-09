# frozen_string_literal: true

describe_current do
  let(:metrics_aggregator) { described_class.new }

  let(:reports_topic) { Karafka::Web.config.topics.consumers.reports.name = create_topic }
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics.name = create_topic }
  let(:states_topic) { Karafka::Web.config.topics.consumers.states.name = create_topic }
  let(:schema_manager) { Karafka::Web::Processing::Consumers::SchemaManager.new }
  let(:state_aggregator) do
    Karafka::Web::Processing::Consumers::Aggregators::State.new(schema_manager)
  end

  before do
    reports_topic
    metrics_topic
    states_topic
  end

  context "when there are no initial metrics" do
    let(:expected_error) { Karafka::Web::Errors::Processing::MissingConsumersMetricsError }

    it { assert_raises(expected_error) { metrics_aggregator.to_h } }
  end

  context "when there are initial metrics but no other data" do
    before do
      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      Karafka::Web::Management::Actions::MigrateStatesData.new.call
      wait_for_state_data
    end

    it "expect to have basic empty stats" do
      hashed = metrics_aggregator.to_h

      assert_equal({ days: [], hours: [], minutes: [], seconds: [] }, hashed[:aggregated])
      assert_equal({ days: [], hours: [], minutes: [], seconds: [] }, hashed[:consumer_groups])
      assert_equal("1.3.0", hashed[:schema_version])
      assert(hashed.key?(:dispatched_at))
    end
  end

  context "when we have data from a multi-topic, multi-partition setup" do
    let(:process1_report) do
      data = Fixtures.consumers_reports_json("multi_partition/v1.4.1_process_1")
      data[:dispatched_at] = Time.now.to_f
      data
    end

    let(:process2_report) do
      data = Fixtures.consumers_reports_json("multi_partition/v1.4.1_process_2")
      data[:dispatched_at] = Time.now.to_f
      data
    end

    before do
      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      Karafka::Web::Management::Actions::MigrateStatesData.new.call
      wait_for_state_data

      [process1_report, process2_report].each_with_index do |report, index|
        state_aggregator.add(report, index)
        metrics_aggregator.add_report(report)
        metrics_aggregator.add_stats(state_aggregator.stats)
      end
    end

    it "expected to compute multi-process states correctly for all the topics" do
      topics1 = metrics_aggregator.to_h[:consumer_groups][:seconds][0][1][:example_app_app]
      topics2 = metrics_aggregator.to_h[:consumer_groups][:seconds][0][1][:example_app_karafka_web]

      assert_equal(5, topics1[:visits][:lag_hybrid])
      assert_equal(271_066, topics1[:visits][:pace])
      assert_equal(0, topics1[:visits][:ls_offset_fd])

      assert_equal(0, topics1[:default][:lag_hybrid])
      assert_equal(813_204, topics1[:default][:pace])
      assert_equal(0, topics1[:default][:ls_offset_fd])

      assert_equal(0, topics2[:karafka_consumers_reports][:lag_hybrid])
      assert_equal(28_972, topics2[:karafka_consumers_reports][:pace])
      assert_equal(0, topics2[:karafka_consumers_reports][:ls_offset_fd])
    end

    context "when lso != ho" do
      # Alter LSO to be less than HO
      let(:process1_report) do
        data = Fixtures.consumers_reports_json("multi_partition/v1.4.1_process_1")
        data[:dispatched_at] = Time.now.to_f

        sg = data[:consumer_groups][:example_app_app][:subscription_groups][:c4ca4238a0b9_0]
        sg[:topics][:visits][:partitions][:"0"][:ls_offset] = 1356

        data
      end

      it "expect to include lso metric as the topic partition lags because of it" do
        topics1 = metrics_aggregator.to_h[:consumer_groups][:seconds][0][1][:example_app_app]

        assert_equal(5_000, topics1[:visits][:ls_offset_fd])
      end
    end
  end
end
