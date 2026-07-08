# frozen_string_literal: true

describe_current do
  let(:state_aggregator) { described_class.new(schema_manager) }

  let(:schema_manager) { Karafka::Web::Processing::Consumers::SchemaManager.new }
  let(:reports_topic) { Karafka::Web.config.topics.consumers.reports.name = create_topic }
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics.name = create_topic }
  let(:states_topic) { Karafka::Web.config.topics.consumers.states.name = create_topic }

  before do
    reports_topic
    metrics_topic
    states_topic

    Karafka::Web::Management::Actions::CreateInitialStates.new.call
    wait_for_state_data(require_ui: false)
    Karafka::Web::Management::Actions::MigrateStatesData.new.call
    wait_for_state_data
  end

  describe "#add_state" do
    context "when process id is a string" do
      let(:report) do
        {
          process: {
            id: "process-1234",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "converts process id to symbol as key" do
        state_aggregator.add_state(report, 100)
        state = state_aggregator.to_h

        assert_includes(state[:processes].keys, :"process-1234")
        assert_equal(100, state[:processes][:"process-1234"][:offset])
        assert_equal(report[:dispatched_at], state[:processes][:"process-1234"][:dispatched_at])
      end

      it "allows updating existing process with string id" do
        # First add
        state_aggregator.add_state(report, 100)

        # Update with new offset
        updated_report = report.dup
        updated_report[:dispatched_at] = Time.now.to_f + 10
        state_aggregator.add_state(updated_report, 200)

        state = state_aggregator.to_h
        process = state[:processes][:"process-1234"]

        assert_equal(200, process[:offset])
        assert_equal(updated_report[:dispatched_at], process[:dispatched_at])
      end
    end

    context "when process id is already a symbol" do
      let(:report) do
        {
          process: {
            id: :"process-5678",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "keeps process id as symbol" do
        state_aggregator.add_state(report, 300)
        state = state_aggregator.to_h

        assert_includes(state[:processes].keys, :"process-5678")
        assert_equal(300, state[:processes][:"process-5678"][:offset])
      end
    end

    context "when updating state from deserialized data" do
      let(:initial_report) do
        {
          process: {
            id: "process-abc",
            status: "running"
          },
          dispatched_at: Time.now.to_f - 100
        }
      end

      let(:new_report) do
        {
          process: {
            id: "process-abc",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      before do
        # Simulate existing state with symbolized keys
        state_aggregator.add_state(initial_report, 50)
      end

      it "correctly updates existing process when keys are already symbols" do
        # This tests the scenario described in the comment where we have
        # deserialized state with symbol keys and need to update it
        state_aggregator.add_state(new_report, 150)

        state = state_aggregator.to_h
        # Should have only one process, not two
        assert_equal(1, state[:processes].keys.size)
        assert_equal(150, state[:processes][:"process-abc"][:offset])
        assert_equal(new_report[:dispatched_at], state[:processes][:"process-abc"][:dispatched_at])
      end
    end

    context "with multiple processes" do
      let(:process1_report) do
        {
          process: {
            id: "worker-1",
            status: "running"
          },
          dispatched_at: Time.now.to_f - 10
        }
      end

      let(:process2_report) do
        {
          process: {
            id: "worker-2",
            status: "running"
          },
          dispatched_at: Time.now.to_f - 5
        }
      end

      it "maintains separate entries for different processes" do
        state_aggregator.add_state(process1_report, 10)
        state_aggregator.add_state(process2_report, 20)

        state = state_aggregator.to_h

        assert_equal([:"worker-1", :"worker-2"].sort, state[:processes].keys.sort)

        assert_equal(10, state[:processes][:"worker-1"][:offset])
        assert_equal(20, state[:processes][:"worker-2"][:offset])
      end
    end
  end

  describe "#add" do
    context "when adding a complete report with string process id" do
      let(:report) do
        data = Fixtures.consumers_reports_json("multi_partition/v1.4.1_process_1")
        data[:dispatched_at] = Time.now.to_f
        # Ensure the process id is a string to test the conversion
        data[:process][:id] = data[:process][:id].to_s
        data
      end

      it "processes the report correctly with symbolized process id" do
        state_aggregator.add(report, 42)
        state = state_aggregator.to_h

        process_id = report[:process][:id].to_sym

        assert_includes(state[:processes].keys, process_id)
        assert_equal(42, state[:processes][process_id][:offset])
      end

      it "increments total counters" do
        initial_state = state_aggregator.to_h
        initial_total = initial_state[:stats][:messages] || 0

        state_aggregator.add(report, 42)

        new_state = state_aggregator.to_h
        new_total = new_state[:stats][:messages]

        assert(new_total > initial_total)
      end

      it "updates stats correctly" do
        state_aggregator.add(report, 42)
        stats = state_aggregator.stats

        assert_kind_of(Hash, stats)
        assert_equal(1, stats[:processes])
        assert(stats[:busy] >= 0)
        assert(stats[:enqueued] >= 0)
      end
    end
  end

  describe "waiting jobs aggregation" do
    # Regression coverage for the dashboard "Pending" counter being undercounted.
    # Counters#pending is `enqueued + waiting`, but the state aggregator never summed
    # `waiting` from incoming reports, so the materialized state always reported
    # `stats[:waiting] == 0` and Pending silently ignored jobs sitting in the
    # scheduler (advanced/recurring/scheduled-message schedulers).
    def report_with_waiting(waiting:, process_id:)
      data = Fixtures.consumers_reports_json("multi_partition/v1.4.1_process_1")
      data[:dispatched_at] = Time.now.to_f
      data[:process][:id] = process_id
      data[:stats][:waiting] = waiting
      data
    end

    it "sums waiting jobs from a single report into the aggregated stats" do
      state_aggregator.add(report_with_waiting(waiting: 7, process_id: "process-1"), 42)

      assert_equal(7, state_aggregator.stats[:waiting])
    end

    it "sums waiting jobs across multiple active reports" do
      state_aggregator.add(report_with_waiting(waiting: 7, process_id: "process-1"), 42)
      state_aggregator.add(report_with_waiting(waiting: 5, process_id: "process-2"), 43)

      assert_equal(12, state_aggregator.stats[:waiting])
    end

    it "resets waiting to zero when reports carry no waiting jobs" do
      state_aggregator.add(report_with_waiting(waiting: 0, process_id: "process-1"), 42)

      assert_equal(0, state_aggregator.stats[:waiting])
    end
  end

  describe "paused partitions lag compensation" do
    # Use small thresholds so tests can simulate crossing them with a few seconds of report
    # time instead of the 60s/30s defaults, while staying well under the (default 30s) process
    # TTL so processes used across multiple `#add` calls in the same test do not get evicted.
    let(:paused_partitions_lag_config) { Karafka::Web.config.processing.paused_partitions_lag }

    before do
      @original_min_pause_duration = paused_partitions_lag_config.min_pause_duration
      @original_refresh_interval = paused_partitions_lag_config.refresh_interval

      paused_partitions_lag_config.min_pause_duration = 2_000
      paused_partitions_lag_config.refresh_interval = 1_000
    end

    after do
      paused_partitions_lag_config.min_pause_duration = @original_min_pause_duration
      paused_partitions_lag_config.refresh_interval = @original_refresh_interval
    end

    # Builds a minimal but complete report with a single consumer group / subscription group /
    # topic / partition, so we can precisely control pause state, offsets and timing.
    def paused_report(
      process_id:,
      dispatched_at:,
      poll_state: "paused",
      committed_offset: 100,
      stored_offset: 100,
      lag: 5,
      lag_stored: 5,
      cg_id: "test_cg",
      topic: "test_topic",
      partition_id: 0,
      status: "running"
    )
      {
        process: {
          id: process_id,
          status: status,
          listeners: { active: 1, standby: 0 },
          workers: 1,
          memory_usage: 100,
          bytes_received: 0,
          bytes_sent: 0
        },
        dispatched_at: dispatched_at,
        stats: {
          busy: 0,
          enqueued: 0,
          waiting: 0,
          utilization: 0,
          total: { batches: 0, jobs: 0, messages: 0, errors: 0, retries: 0, dead: 0 }
        },
        consumer_groups: {
          cg_id => {
            id: cg_id,
            subscription_groups: {
              "sg_0" => {
                id: "sg_0",
                state: {
                  state: "up",
                  join_state: "steady",
                  stateage: 0,
                  rebalance_age: 0,
                  rebalance_cnt: 0,
                  rebalance_reason: "",
                  poll_age: 0
                },
                topics: {
                  topic => {
                    name: topic,
                    partitions: {
                      partition_id.to_s => {
                        lag: lag,
                        lag_d: 0,
                        lag_stored: lag_stored,
                        lag_stored_d: 0,
                        committed_offset: committed_offset,
                        committed_offset_fd: 0,
                        stored_offset: stored_offset,
                        stored_offset_fd: 0,
                        fetch_state: (poll_state == "paused") ? "paused" : "active",
                        hi_offset: 100,
                        hi_offset_fd: 0,
                        lo_offset: 0,
                        eof_offset: 100,
                        ls_offset: 100,
                        ls_offset_d: 0,
                        ls_offset_fd: 0,
                        id: partition_id,
                        poll_state: poll_state,
                        poll_state_ch: 0,
                        transactional: false
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

    let(:t0) { Time.now.to_f }

    it "does not query the cluster and reports an empty correction when nothing is paused" do
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0, poll_state: "active"), 1)

      assert_equal({}, state_aggregator.to_h[:paused_partitions_lag])
    end

    it "does not consider a freshly paused partition eligible yet" do
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0), 1)

      assert_equal({}, state_aggregator.to_h[:paused_partitions_lag])
    end

    it "becomes eligible once continuously paused for at least the configured minimum" do
      Karafka::Admin.any_instance.stubs(:read_partition_offsets).returns(
        [{ topic: "test_topic", partition: 0, offset: 1_000, timestamp: 0, leader_epoch: 0 }]
      )

      # First observation: partition just became paused, not eligible yet
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0), 1)
      # 3s later (report time), still paused: crosses the configured 2s minimum
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 3), 2)

      correction = state_aggregator.to_h[:paused_partitions_lag]

      assert_equal(900, correction["test_cg"]["test_topic"]["0"][:lag])
      assert_equal(900, correction["test_cg"]["test_topic"]["0"][:lag_stored])
    end

    it "computes lag/lag_stored independently and clamps negative results to zero" do
      Karafka::Admin.any_instance.stubs(:read_partition_offsets).returns(
        [{ topic: "test_topic", partition: 0, offset: 1_000, timestamp: 0, leader_epoch: 0 }]
      )

      state_aggregator.add(
        paused_report(process_id: "p1", dispatched_at: t0, committed_offset: 1_200, stored_offset: 400),
        1
      )
      state_aggregator.add(
        paused_report(process_id: "p1", dispatched_at: t0 + 3, committed_offset: 1_200, stored_offset: 400),
        2
      )

      correction = state_aggregator.to_h[:paused_partitions_lag]["test_cg"]["test_topic"]["0"]

      # committed_offset (1200) is ahead of the fresh watermark (1000), clamp to 0
      assert_equal(0, correction[:lag])
      assert_equal(600, correction[:lag_stored])
    end

    it "batches multiple eligible partitions across topics into a single admin call" do
      Karafka::Admin.any_instance.expects(:read_partition_offsets).once.with(
        {
          "topic_a" => [{ partition: 0, offset: :latest }],
          "topic_b" => [{ partition: 1, offset: :latest }]
        },
        isolation_level: ::Karafka::Admin::IsolationLevels::READ_COMMITTED
      ).returns(
        [
          { topic: "topic_a", partition: 0, offset: 500, timestamp: 0, leader_epoch: 0 },
          { topic: "topic_b", partition: 1, offset: 700, timestamp: 0, leader_epoch: 0 }
        ]
      )

      report_a = ->(dispatched_at) do
        paused_report(
          process_id: "p1", dispatched_at: dispatched_at, cg_id: "cg_a", topic: "topic_a", partition_id: 0
        )
      end

      report_b = ->(dispatched_at) do
        paused_report(
          process_id: "p2", dispatched_at: dispatched_at, cg_id: "cg_b", topic: "topic_b", partition_id: 1
        )
      end

      state_aggregator.add(report_a.call(t0), 1)
      state_aggregator.add(report_b.call(t0), 2)
      state_aggregator.add(report_a.call(t0 + 3), 3)

      correction = state_aggregator.to_h[:paused_partitions_lag]

      assert(correction["cg_a"]["topic_a"]["0"])
      assert(correction["cg_b"]["topic_b"]["1"])
    end

    it "throttles refreshes to the configured interval" do
      Karafka::Admin.any_instance.expects(:read_partition_offsets).once.returns(
        [{ topic: "test_topic", partition: 0, offset: 1_000, timestamp: 0, leader_epoch: 0 }]
      )

      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0), 1)
      # Crosses the 2s (configured) pause minimum: first (and only) admin call
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 3), 2)
      # Only 0.5s later (report time): well within the 1s refresh throttle, no second call
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 3.5), 3)

      assert_equal(900, state_aggregator.to_h[:paused_partitions_lag]["test_cg"]["test_topic"]["0"][:lag])
    end

    it "resets the pause timer when a partition resumes before becoming eligible again" do
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0), 1)
      # Not yet eligible (1s < 2s minimum)
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 1), 2)
      # Resumes: pause bookkeeping for this partition is cleared
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 1.5, poll_state: "active"), 3)
      # Paused again: this is a brand new pause, not a continuation of the earlier one
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 2), 4)
      # Only 1.5s into the new pause: still not eligible if the timer correctly reset
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 3.5), 5)

      assert_equal({}, state_aggregator.to_h[:paused_partitions_lag])
    end

    it "gracefully degrades and preserves the previous correction when the admin call fails" do
      Karafka::Admin.any_instance.stubs(:read_partition_offsets)
        .returns([{ topic: "test_topic", partition: 0, offset: 1_000, timestamp: 0, leader_epoch: 0 }])
        .then.raises(Rdkafka::AbstractHandle::WaitTimeoutError)

      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0), 1)
      # First successful refresh
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 3), 2)

      first_correction = state_aggregator.to_h[:paused_partitions_lag]

      assert_equal(900, first_correction["test_cg"]["test_topic"]["0"][:lag])

      # Next refresh cycle fails: the previous correction must be left untouched
      state_aggregator.add(paused_report(process_id: "p1", dispatched_at: t0 + 4.5), 3)

      assert_equal(first_correction, state_aggregator.to_h[:paused_partitions_lag])
    end

    it "queries the real cluster for a fresh watermark and computes an accurate lag" do
      topic = create_topic
      produce_many(topic, Array.new(10) { SecureRandom.uuid })

      state_aggregator.add(
        paused_report(
          process_id: "p1",
          dispatched_at: t0,
          topic: topic,
          committed_offset: 2,
          stored_offset: 2
        ),
        1
      )
      state_aggregator.add(
        paused_report(
          process_id: "p1",
          dispatched_at: t0 + 3,
          topic: topic,
          committed_offset: 2,
          stored_offset: 2
        ),
        2
      )

      correction = state_aggregator.to_h[:paused_partitions_lag]["test_cg"][topic]["0"]

      assert_equal(8, correction[:lag])
      assert_equal(8, correction[:lag_stored])
    end
  end

  describe "#to_h and #stats" do
    it "includes schema version" do
      state = state_aggregator.to_h

      assert_equal("1.5.0", state[:schema_version])
    end

    it "includes dispatched_at timestamp" do
      state = state_aggregator.to_h

      assert_kind_of(Float, state[:dispatched_at])
      assert(state[:dispatched_at] > 0)
    end

    it "includes schema state" do
      state = state_aggregator.to_h

      assert_kind_of(String, state[:schema_state])
    end

    it "returns a copy of the stats" do
      stats1 = state_aggregator.stats
      stats2 = state_aggregator.stats

      assert_equal(stats2, stats1)
      refute_same(stats2, stats1)
    end
  end
end
