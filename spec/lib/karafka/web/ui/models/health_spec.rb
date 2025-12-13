# frozen_string_literal: true

RSpec.describe_current do
  subject(:stats) { described_class.current(state) }

  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before { Karafka::Web.config.topics.consumers.reports.name = reports_topic }

  context 'when none of the processes are active' do
    it { expect(stats).to eq({}) }
  end

  context 'when there are active processes' do
    let(:cg) { 'example_app6_app' }
    let(:topic) { 'default' }

    before do
      produce(reports_topic, report.to_json)
      produce(reports_topic, report.to_json)
    end

    it 'expect to have proper consumer group and details' do
      expect(stats.keys).to eq(%w[example_app6_app])
      expect(stats[cg][:rebalanced_at]).to eq(2_690_818_656.575_513)
      expect(stats[cg][:topics].keys).to eq(%w[default test2 visits])

      topic_data = stats[cg][:topics][topic]

      expect(topic_data.keys).to eq(%i[partitions partitions_count])
      expect(topic_data[:partitions].keys).to eq([0])
      expect(topic_data[:partitions_count]).to eq(1)

      partition_data = topic_data[:partitions][0]

      expect(partition_data[:lag]).to eq(13)
      expect(partition_data[:lag_d]).to eq(2)
      expect(partition_data[:lag_stored]).to eq(213_731_273)
      expect(partition_data[:lag_stored_d]).to eq(-3)
      expect(partition_data[:lag_hybrid]).to eq(213_731_273)
      expect(partition_data[:lag_hybrid_d]).to eq(-3)
      expect(partition_data[:committed_offset]).to eq(327_343)
      expect(partition_data[:stored_offset]).to eq(327_355)
      expect(partition_data[:fetch_state]).to eq('active')
      expect(partition_data[:hi_offset]).to eq(327_356)
      expect(partition_data[:id]).to eq(0)
      expect(partition_data[:poll_state]).to eq('active')
      expect(partition_data[:process][:schema_version]).to eq('1.6.0')
      expect(partition_data[:process][:type]).to eq('consumer')
      expect(partition_data[:process][:dispatched_at]).to eq(2_690_883_271.575_513)
      expect(partition_data[:process][:process][:concurrency]).to eq(2)
      expect(partition_data[:process][:process][:cpus]).to eq(8)
      expect(partition_data[:process][:process][:cpu_usage]).to eq([1.33, 1.1, 1.1])
      expect(partition_data[:process][:process][:listeners]).to eq(active: 2, standby: 0)
      expect(partition_data[:process][:process][:memory_size]).to eq(32_763_220)
      expect(partition_data[:process][:process][:id]).to eq('shinra:1:1')
      expect(partition_data[:process][:process][:started_at]).to eq(2_690_818_651.82_293)
      expect(partition_data[:process][:process][:status]).to eq('running')
      expect(partition_data[:process][:process][:tags]).to eq(%w[#8cbff36])
      expect(partition_data[:process][:versions][:karafka]).to eq('2.1.8')
      expect(partition_data[:process][:versions][:karafka_core]).to eq('2.1.1')
      expect(partition_data[:process][:versions][:karafka_web]).to eq('0.7.0')
      expect(partition_data[:process][:versions][:librdkafka]).to eq('2.1.1')
      expect(partition_data[:process][:versions][:rdkafka]).to eq('0.13.2')
      expect(partition_data[:process][:versions][:ruby]).to eq('ruby 3.2.2-53 e51014')
      expect(partition_data[:process][:versions][:waterdrop]).to eq('2.6.3')
      expect(partition_data[:process][:stats][:busy]).to eq(1)
      expect(partition_data[:process][:stats][:enqueued]).to eq(0)
      expect(partition_data[:process][:stats][:utilization]).to eq(5.634_919_553_399_087)
      expect(partition_data[:process][:stats][:total][:batches]).to eq(9)
      expect(partition_data[:process][:stats][:total][:dead]).to eq(0)
      expect(partition_data[:process][:stats][:total][:errors]).to eq(0)
      expect(partition_data[:process][:stats][:total][:messages]).to eq(22)
      expect(partition_data[:process][:stats][:total][:retries]).to eq(0)
      expect(partition_data[:subscription_group_id]).to eq('c4ca4238a0b9_0')

      cgs = partition_data[:process][:consumer_groups]
      sg = cgs[:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]

      expect(cgs.keys).to eq(%i[example_app6_app example_app6_karafka_web])
      expect(cgs[:example_app6_app].keys).to eq(%i[id subscription_groups])
      expect(cgs[:example_app6_app][:id]).to eq('example_app6_app')
      expect(cgs[:example_app6_app][:subscription_groups].keys).to eq(%i[c4ca4238a0b9_0])
      expect(sg.keys).to eq(%i[id state topics])
      expect(sg[:id]).to eq('c4ca4238a0b9_0')
      expect(sg[:state][:join_state]).to eq('steady')
      expect(sg[:state][:rebalance_age]).to eq(64_615_986)
      expect(sg[:state][:rebalance_cnt]).to eq(1)
      expect(sg[:state][:rebalance_reason]).to eq('Metadata for subscribed topic(s) has changed')
      expect(sg[:state][:state]).to eq('up')
      expect(sg[:state][:stateage]).to eq(64_618_193)
      expect(sg[:topics].to_h.keys).to eq(%i[default test2 visits])
      expect(sg[:topics][:default].keys).to eq(%i[name partitions partitions_cnt])
      expect(sg[:topics][:default][:name]).to eq('default')
      expect(sg[:topics][:default][:partitions_cnt]).to eq(1)
      expect(sg[:topics][:default][:partitions].keys).to eq(%i[0])

      keys = %i[
        lag lag_d lag_stored lag_stored_d committed_offset stored_offset fetch_state hi_offset id
        poll_state process hi_offset_fd stored_offset_fd lo_offset ls_offset ls_offset_fd
        eof_offset committed_offset_fd poll_state_ch partition_id lag_hybrid lag_hybrid_d
        subscription_group_id transactional
      ].sort
      expect(sg[:topics][:default][:partitions][:'0'].keys.sort).to eq(keys)
    end
  end
end
