# frozen_string_literal: true

describe_current do
  let(:refresh_interval) { 1_000 }
  let(:min_pause_duration) { 2_000 }
  let(:query_timeout) { 60_000 }

  let(:paused_partitions_lag_config) { Karafka::Web.config.processing.paused_partitions_lag }

  before do
    @original_min_pause_duration = paused_partitions_lag_config.min_pause_duration
    @original_refresh_interval = paused_partitions_lag_config.refresh_interval
    @original_query_timeout = paused_partitions_lag_config.query_timeout

    paused_partitions_lag_config.min_pause_duration = min_pause_duration
    paused_partitions_lag_config.refresh_interval = refresh_interval
    paused_partitions_lag_config.query_timeout = query_timeout
  end

  after do
    paused_partitions_lag_config.min_pause_duration = @original_min_pause_duration
    paused_partitions_lag_config.refresh_interval = @original_refresh_interval
    paused_partitions_lag_config.query_timeout = @original_query_timeout
  end

  let(:aggregated_from) { 1_000_000.0 }
  let(:state) { { paused_partitions_lag: {} } }
  let(:paused_since) { {} }
  let(:paused_partitions_lag_refreshed_at) { nil }
  let(:active_reports) { {} }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: state,
      active_reports: active_reports,
      aggregated_from: aggregated_from,
      report: {},
      offset: 1,
      paused_since: paused_since,
      paused_partitions_lag_refreshed_at: paused_partitions_lag_refreshed_at
    )
  end

  let(:step) { described_class.new(context) }

  def build_report(
    status: "running",
    poll_state: "paused",
    cg_id: "cg",
    topic: "topic",
    partition_id: 0,
    committed_offset: 100,
    stored_offset: 100
  )
    {
      process: { status: status },
      consumer_groups: {
        cg_id => {
          subscription_groups: {
            sg_0: {
              topics: {
                topic => {
                  partitions: {
                    partition_id => {
                      poll_state: poll_state,
                      committed_offset: committed_offset,
                      stored_offset: stored_offset
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  context "when the last refresh happened within the throttle window" do
    let(:paused_partitions_lag_refreshed_at) { aggregated_from - (refresh_interval / 1_000.0) + 0.5 }
    let(:active_reports) { { p1: build_report } }
    let(:paused_since) { { ["cg", "topic", 0] => aggregated_from - 100 } }

    it "does not query the cluster nor touch the materialized correction" do
      Karafka::Admin.expects(:new).never

      state[:paused_partitions_lag] = { untouched: true }
      step.call

      assert_equal({ untouched: true }, state[:paused_partitions_lag])
    end
  end

  context "when there are no eligible paused partitions" do
    let(:active_reports) { {} }

    it "sets an empty correction" do
      step.call

      assert_equal({}, state[:paused_partitions_lag])
    end

    it "updates the refreshed_at throttle timestamp" do
      step.call

      assert_equal(aggregated_from, context.paused_partitions_lag_refreshed_at)
    end
  end

  context "when a partition has not been paused long enough" do
    let(:active_reports) { { p1: build_report } }
    let(:paused_since) { { ["cg", "topic", 0] => aggregated_from - 1 } }

    it "does not query the cluster and reports an empty correction" do
      Karafka::Admin.expects(:new).never

      step.call

      assert_equal({}, state[:paused_partitions_lag])
    end
  end

  context "when a partition is eligible" do
    let(:active_reports) { { p1: build_report(committed_offset: 100, stored_offset: 100) } }
    let(:paused_since) { { ["cg", "topic", 0] => aggregated_from - 100 } }

    it "queries the cluster and computes a corrected lag" do
      Karafka::Admin.any_instance.expects(:read_partition_offsets).with(
        { "topic" => [{ partition: 0, offset: :latest }] },
        isolation_level: ::Karafka::Admin::IsolationLevels::READ_COMMITTED
      ).returns(
        [{ topic: "topic", partition: 0, offset: 1_000, timestamp: 0, leader_epoch: 0 }]
      )

      step.call

      correction = state[:paused_partitions_lag]["cg"]["topic"]["0"]

      assert_equal(900, correction[:lag])
      assert_equal(900, correction[:lag_stored])
    end

    it "clamps a negative lag (watermark behind the committed offset) to zero" do
      Karafka::Admin.any_instance.stubs(:read_partition_offsets).returns(
        [{ topic: "topic", partition: 0, offset: 50, timestamp: 0, leader_epoch: 0 }]
      )

      step.call

      correction = state[:paused_partitions_lag]["cg"]["topic"]["0"]

      assert_equal(0, correction[:lag])
      assert_equal(0, correction[:lag_stored])
    end
  end

  context "when the admin call fails" do
    let(:active_reports) { { p1: build_report } }
    let(:paused_since) { { ["cg", "topic", 0] => aggregated_from - 100 } }
    let(:state) { { paused_partitions_lag: { "cg" => { "topic" => { "0" => { lag: 42 } } } } } }

    it "leaves the previous correction untouched instead of wiping it out" do
      Karafka::Admin.any_instance.stubs(:read_partition_offsets).raises(
        Rdkafka::AbstractHandle::WaitTimeoutError
      )

      step.call

      assert_equal({ "cg" => { "topic" => { "0" => { lag: 42 } } } }, state[:paused_partitions_lag])
    end
  end
end
