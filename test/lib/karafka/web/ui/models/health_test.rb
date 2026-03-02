# frozen_string_literal: true

describe_current do
  let(:stats) { described_class.current(state) }

  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before { Karafka::Web.config.topics.consumers.reports.name = reports_topic }

  context "when none of the processes are active" do
    it { assert_equal({}, stats) }
  end

  context "when there are active processes" do
    let(:cg) { "example_app6_app" }
    let(:topic) { "default" }

    before do
      produce(reports_topic, report.to_json)
      produce(reports_topic, report.to_json)
    end

    it "expect to have proper consumer group and details" do
      assert_equal(%w[example_app6_app], stats.keys)
      assert_equal(2_690_818_656.575_513, stats[cg][:rebalanced_at])
      assert_equal(%w[default test2 visits], stats[cg][:topics].keys)

      topic_data = stats[cg][:topics][topic]

      assert_equal(%i[partitions partitions_count], topic_data.keys)
      assert_equal([0], topic_data[:partitions].keys)
      assert_equal(1, topic_data[:partitions_count])

      partition_data = topic_data[:partitions][0]

      assert_equal(13, partition_data[:lag])
      assert_equal(2, partition_data[:lag_d])
      assert_equal(213_731_273, partition_data[:lag_stored])
      assert_equal(-3, partition_data[:lag_stored_d])
      assert_equal(213_731_273, partition_data[:lag_hybrid])
      assert_equal(-3, partition_data[:lag_hybrid_d])
      assert_equal(327_343, partition_data[:committed_offset])
      assert_equal(327_355, partition_data[:stored_offset])
      assert_equal("active", partition_data[:fetch_state])
      assert_equal(327_356, partition_data[:hi_offset])
      assert_equal(0, partition_data[:id])
      assert_equal("active", partition_data[:poll_state])
      assert_equal("1.7.0", partition_data[:process][:schema_version])
      assert_equal("consumer", partition_data[:process][:type])
      assert_equal(2_690_883_271.575_513, partition_data[:process][:dispatched_at])
      assert_equal(2, partition_data[:process][:process][:concurrency])
      assert_equal(8, partition_data[:process][:process][:cpus])
      assert_equal([1.33, 1.1, 1.1], partition_data[:process][:process][:cpu_usage])
      assert_equal({active: 2, standby: 0}, partition_data[:process][:process][:listeners])
      assert_equal(32_763_220, partition_data[:process][:process][:memory_size])
      assert_equal("shinra:1:1", partition_data[:process][:process][:id])
      assert_equal(2_690_818_651.82_293, partition_data[:process][:process][:started_at])
      assert_equal("running", partition_data[:process][:process][:status])
      assert_equal(%w[#8cbff36], partition_data[:process][:process][:tags])
      assert_equal("2.1.8", partition_data[:process][:versions][:karafka])
      assert_equal("2.1.1", partition_data[:process][:versions][:karafka_core])
      assert_equal("0.7.0", partition_data[:process][:versions][:karafka_web])
      assert_equal("2.1.1", partition_data[:process][:versions][:librdkafka])
      assert_equal("0.13.2", partition_data[:process][:versions][:rdkafka])
      assert_equal("ruby 3.2.2-53 e51014", partition_data[:process][:versions][:ruby])
      assert_equal("2.6.3", partition_data[:process][:versions][:waterdrop])
      assert_equal(1, partition_data[:process][:stats][:busy])
      assert_equal(0, partition_data[:process][:stats][:enqueued])
      assert_equal(5.634_919_553_399_087, partition_data[:process][:stats][:utilization])
      assert_equal(9, partition_data[:process][:stats][:total][:batches])
      assert_equal(0, partition_data[:process][:stats][:total][:dead])
      assert_equal(0, partition_data[:process][:stats][:total][:errors])
      assert_equal(22, partition_data[:process][:stats][:total][:messages])
      assert_equal(0, partition_data[:process][:stats][:total][:retries])
      assert_equal("c4ca4238a0b9_0", partition_data[:subscription_group_id])

      cgs = partition_data[:process][:consumer_groups]
      sg = cgs[:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]

      assert_equal(%i[example_app6_app example_app6_karafka_web], cgs.keys)
      assert_equal(%i[id subscription_groups], cgs[:example_app6_app].keys)
      assert_equal("example_app6_app", cgs[:example_app6_app][:id])
      assert_equal(%i[c4ca4238a0b9_0], cgs[:example_app6_app][:subscription_groups].keys)
      assert_equal(%i[id instance_id state topics], sg.keys)
      assert_equal("c4ca4238a0b9_0", sg[:id])
      assert_equal(false, sg[:instance_id])
      assert_equal("steady", sg[:state][:join_state])
      assert_equal(64_615_986, sg[:state][:rebalance_age])
      assert_equal(1, sg[:state][:rebalance_cnt])
      assert_equal("Metadata for subscribed topic(s) has changed", sg[:state][:rebalance_reason])
      assert_equal("up", sg[:state][:state])
      assert_equal(64_618_193, sg[:state][:stateage])
      assert_equal(%i[default test2 visits], sg[:topics].to_h.keys)
      assert_equal(%i[name partitions partitions_cnt], sg[:topics][:default].keys)
      assert_equal("default", sg[:topics][:default][:name])
      assert_equal(1, sg[:topics][:default][:partitions_cnt])
      assert_equal(%i[0], sg[:topics][:default][:partitions].keys)

      keys = %i[
        lag lag_d lag_stored lag_stored_d committed_offset stored_offset fetch_state hi_offset id
        poll_state process hi_offset_fd stored_offset_fd lo_offset ls_offset ls_offset_fd
        eof_offset committed_offset_fd poll_state_ch partition_id lag_hybrid lag_hybrid_d
        subscription_group_id instance_id transactional
      ].sort
      assert_equal(keys, sg[:topics][:default][:partitions][:"0"].keys.sort)
    end
  end
end
