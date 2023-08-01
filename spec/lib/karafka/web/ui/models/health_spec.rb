# frozen_string_literal: true

RSpec.describe_current do
  subject(:stats) { described_class.current(state) }

  let(:state) { JSON.parse(fixtures_file('consumers_state.json'), symbolize_names: true) }
  let(:report) { JSON.parse(fixtures_file('consumer_report.json'), symbolize_names: true) }
  let(:reports_topic) { create_topic }

  before { Karafka::Web.config.topics.consumers.reports = reports_topic }

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

      expect(topic_data.keys).to eq([0])
      expect(topic_data[0][:lag]).to eq(13)
      expect(topic_data[0][:lag_d]).to eq(2)
      expect(topic_data[0][:lag_stored]).to eq(1)
      expect(topic_data[0][:committed_offset]).to eq(327_343)
      expect(topic_data[0][:stored_offset]).to eq(327_355)
      expect(topic_data[0][:fetch_state]).to eq('active')
      expect(topic_data[0][:hi_offset]).to eq(327_356)
      expect(topic_data[0][:id]).to eq(0)
      expect(topic_data[0][:poll_state]).to eq('active')
      expect(topic_data[0][:process][:schema_version]).to eq('1.2.2')
      expect(topic_data[0][:process][:type]).to eq('consumer')
      expect(topic_data[0][:process][:dispatched_at]).to eq(2_690_883_271.575_513)
      expect(topic_data[0][:process][:process][:concurrency]).to eq(2)
      expect(topic_data[0][:process][:process][:cpu_count]).to eq(8)
      expect(topic_data[0][:process][:process][:cpu_usage]).to eq([1.33, 1.1, 1.1])
      expect(topic_data[0][:process][:process][:listeners]).to eq(2)
      expect(topic_data[0][:process][:process][:memory_size]).to eq(32_763_220)
      expect(topic_data[0][:process][:process][:name]).to eq('shinra:1:1')
      expect(topic_data[0][:process][:process][:started_at]).to eq(2_690_818_651.82_293)
      expect(topic_data[0][:process][:process][:status]).to eq('running')
      expect(topic_data[0][:process][:process][:tags]).to eq(%w[#8cbff36])
      expect(topic_data[0][:process][:versions][:karafka]).to eq('2.1.8')
      expect(topic_data[0][:process][:versions][:karafka_core]).to eq('2.1.1')
      expect(topic_data[0][:process][:versions][:karafka_web]).to eq('0.7.0')
      expect(topic_data[0][:process][:versions][:librdkafka]).to eq('2.1.1')
      expect(topic_data[0][:process][:versions][:rdkafka]).to eq('0.13.2')
      expect(topic_data[0][:process][:versions][:ruby]).to eq('ruby 3.2.2-53 e51014')
      expect(topic_data[0][:process][:versions][:waterdrop]).to eq('2.6.3')
      expect(topic_data[0][:process][:stats][:busy]).to eq(1)
      expect(topic_data[0][:process][:stats][:enqueued]).to eq(0)
      expect(topic_data[0][:process][:stats][:utilization]).to eq(5.634_919_553_399_087)
      expect(topic_data[0][:process][:stats][:total][:batches]).to eq(9)
      expect(topic_data[0][:process][:stats][:total][:dead]).to eq(0)
      expect(topic_data[0][:process][:stats][:total][:errors]).to eq(0)
      expect(topic_data[0][:process][:stats][:total][:messages]).to eq(22)
      expect(topic_data[0][:process][:stats][:total][:retries]).to eq(0)

      cgs = topic_data[0][:process][:consumer_groups]
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
      expect(sg[:topics][:default].keys).to eq(%i[name partitions])
      expect(sg[:topics][:default][:name]).to eq('default')
      expect(sg[:topics][:default][:partitions].keys).to eq(%i[0])

      keys = %i[
        lag lag_d lag_stored lag_stored_d committed_offset stored_offset fetch_state hi_offset id
        poll_state process
      ]
      expect(sg[:topics][:default][:partitions]['0'.to_sym].keys).to eq(keys)
    end
  end
end
