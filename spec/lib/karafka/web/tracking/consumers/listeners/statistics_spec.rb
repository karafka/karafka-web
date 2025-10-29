# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:statistics) { Fixtures.json('emitted_statistics', symbolize_names: false) }
  let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }
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

  before do
    # This data is set in the connections listener prior to any polling
    sampler.track do |sampler|
      sampler.subscription_groups['sgid'][:polled_at] = sampler.monotonic_now
    end

    listener.on_statistics_emitted(event)
  end

  after { sampler.consumer_groups.clear }

  it { expect(sampler.consumer_groups['cgid']).not_to be_empty }
  it { expect(sampler.consumer_groups['cgid'][:id]).to eq('cgid') }
  it { expect(sg_details.keys).to include('sgid') }
  it { expect(sg_details['sgid'][:id]).to eq('sgid') }
  it { expect(sg_details['sgid'][:state][:join_state]).to eq('steady') }
  it { expect(sg_details['sgid'][:state][:rebalance_age]).to eq(9_997) }
  it { expect(sg_details['sgid'][:state][:rebalance_cnt]).to eq(1) }
  it { expect(sg_details['sgid'][:state][:rebalance_reason]).to include('Metadata for') }
  it { expect(sg_details['sgid'][:state][:state]).to eq('up') }
  it { expect(sg_details['sgid'][:state][:stateage]).to eq(9_998) }
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

  context 'when statistics contain -1 partition' do
    it 'excludes -1 partition from partitions_cnt' do
      # Fixture has partitions "0" and "-1" for each topic, so count should be 1
      expect(sg_details['sgid'][:topics]['default'][:partitions_cnt]).to eq(1)
      expect(sg_details['sgid'][:topics]['test2'][:partitions_cnt]).to eq(1)
      expect(sg_details['sgid'][:topics]['visits'][:partitions_cnt]).to eq(1)
    end

    it 'does not include -1 partition in partitions hash' do
      expect(sg_details['sgid'][:topics]['default'][:partitions].keys).not_to include(-1)
      expect(sg_details['sgid'][:topics]['test2'][:partitions].keys).not_to include(-1)
      expect(sg_details['sgid'][:topics]['visits'][:partitions].keys).not_to include(-1)
    end
  end
end
