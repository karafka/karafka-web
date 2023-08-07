# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:statistics) { JSON.parse(fixtures_file('emitted_statistics.json')) }
  let(:sampler) { ::Karafka::Web.config.tracking.consumers.sampler }
  let(:sg_details) { sampler.consumer_groups['cgid'][:subscription_groups] }
  let(:default_p0) { sg_details['sgid'][:topics]['default'][:partitions][0] }
  let(:test2_p0) { sg_details['sgid'][:topics]['test2'][:partitions][0] }
  let(:visits_p0) { sg_details['sgid'][:topics]['visits'][:partitions][0] }
  let(:event) do
    {
      consumer_group_id: 'cgid',
      subscription_group_id: 'sgid',
      statistics: statistics
    }
  end

  before { listener.on_statistics_emitted(event) }

  it { expect(sampler.consumer_groups['cgid']).not_to be_empty }
  it { expect(sampler.consumer_groups['cgid'][:id]).to eq('cgid') }
  it { expect(sg_details.keys).to include('sgid') }
  it { expect(sg_details['sgid'][:id]).to eq('sgid') }
  it { expect(sg_details['sgid'][:state]['join_state']).to eq('steady') }
  it { expect(sg_details['sgid'][:state]['rebalance_age']).to eq(9_997) }
  it { expect(sg_details['sgid'][:state]['rebalance_cnt']).to eq(1) }
  it { expect(sg_details['sgid'][:state]['rebalance_reason']).to include('Metadata for') }
  it { expect(sg_details['sgid'][:state]['state']).to eq('up') }
  it { expect(sg_details['sgid'][:state]['stateage']).to eq(9_998) }
  it { expect(sg_details['sgid'][:topics]['default'][:name]).to eq('default') }

  it { expect(default_p0[:committed_offset]).to eq(2_857_330) }
  it { expect(default_p0[:fetch_state]).to eq('active') }
  it { expect(default_p0[:hi_offset]).to eq(2_930_898) }
  it { expect(default_p0[:id]).to eq(0) }
  it { expect(default_p0[:lag]).to eq(73_568) }
  it { expect(default_p0[:lag_d]).to eq(-1856) }
  it { expect(default_p0[:lag_stored]).to eq(71_705) }
  it { expect(default_p0[:lag_stored_d]).to eq(-1811) }
  it { expect(default_p0[:poll_state]).to eq('active') }
  it { expect(default_p0[:stored_offset]).to eq(2_859_193) }

  it { expect(test2_p0[:committed_offset]).to eq(-1_001) }
  it { expect(test2_p0[:fetch_state]).to eq('active') }
  it { expect(test2_p0[:hi_offset]).to eq(0) }
  it { expect(test2_p0[:id]).to eq(0) }
  it { expect(test2_p0[:lag]).to eq(-1) }
  it { expect(test2_p0[:lag_d]).to eq(0) }
  it { expect(test2_p0[:lag_stored]).to eq(-1) }
  it { expect(test2_p0[:lag_stored_d]).to eq(0) }
  it { expect(test2_p0[:poll_state]).to eq('active') }
  it { expect(test2_p0[:stored_offset]).to eq(-1_001) }

  it { expect(visits_p0[:committed_offset]).to eq(52) }
  it { expect(visits_p0[:fetch_state]).to eq('active') }
  it { expect(visits_p0[:hi_offset]).to eq(52) }
  it { expect(visits_p0[:id]).to eq(0) }
  it { expect(visits_p0[:lag]).to eq(0) }
  it { expect(visits_p0[:lag_d]).to eq(0) }
  it { expect(visits_p0[:lag_stored]).to eq(-1) }
  it { expect(visits_p0[:lag_stored_d]).to eq(0) }
  it { expect(visits_p0[:poll_state]).to eq('active') }
  it { expect(visits_p0[:stored_offset]).to eq(-1_001) }
end
