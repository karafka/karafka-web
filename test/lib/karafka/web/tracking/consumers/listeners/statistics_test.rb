# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:statistics) { Fixtures.json("emitted_statistics", symbolize_names: false) }
  let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }
  let(:sg_details) { sampler.consumer_groups["cgid"][:subscription_groups] }
  let(:default_p0) { sg_details["sgid"][:topics]["default"][:partitions][0] }
  let(:test2_p0) { sg_details["sgid"][:topics]["test2"][:partitions][0] }
  let(:visits_p0) { sg_details["sgid"][:topics]["visits"][:partitions][0] }
  let(:event) do
    {
      consumer_group_id: "cgid",
      subscription_group_id: "sgid",
      statistics: statistics
    }
  end

  before do
    # This data is set in the connections listener prior to any polling
    sampler.track do |sampler|
      sampler.subscription_groups["sgid"][:polled_at] = sampler.monotonic_now
    end

    listener.on_statistics_emitted(event)
  end

  after { sampler.consumer_groups.clear }

  it { refute_empty(sampler.consumer_groups["cgid"]) }
  it { assert_equal("cgid", sampler.consumer_groups["cgid"][:id]) }
  it { assert_includes(sg_details.keys, "sgid") }
  it { assert_equal("sgid", sg_details["sgid"][:id]) }
  it { assert_equal("steady", sg_details["sgid"][:state][:join_state]) }
  it { assert_equal(9_997, sg_details["sgid"][:state][:rebalance_age]) }
  it { assert_equal(1, sg_details["sgid"][:state][:rebalance_cnt]) }
  it { assert_includes(sg_details["sgid"][:state][:rebalance_reason], "Metadata for") }
  it { assert_equal("up", sg_details["sgid"][:state][:state]) }
  it { assert_equal(9_998, sg_details["sgid"][:state][:stateage]) }
  it { assert_equal("default", sg_details["sgid"][:topics]["default"][:name]) }

  it { assert_equal(2_857_330, default_p0[:committed_offset]) }
  it { assert_equal("active", default_p0[:fetch_state]) }
  it { assert_equal(2_930_898, default_p0[:hi_offset]) }
  it { assert_equal(0, default_p0[:id]) }
  it { assert_equal(73_568, default_p0[:lag]) }
  it { assert_equal(-1856, default_p0[:lag_d]) }
  it { assert_equal(71_705, default_p0[:lag_stored]) }
  it { assert_equal(-1811, default_p0[:lag_stored_d]) }
  it { assert_equal("active", default_p0[:poll_state]) }
  it { assert_equal(2_859_193, default_p0[:stored_offset]) }

  it { assert_equal(-1_001, test2_p0[:committed_offset]) }
  it { assert_equal("active", test2_p0[:fetch_state]) }
  it { assert_equal(0, test2_p0[:hi_offset]) }
  it { assert_equal(0, test2_p0[:id]) }
  it { assert_equal(-1, test2_p0[:lag]) }
  it { assert_equal(0, test2_p0[:lag_d]) }
  it { assert_equal(-1, test2_p0[:lag_stored]) }
  it { assert_equal(0, test2_p0[:lag_stored_d]) }
  it { assert_equal("active", test2_p0[:poll_state]) }
  it { assert_equal(-1_001, test2_p0[:stored_offset]) }

  it { assert_equal(52, visits_p0[:committed_offset]) }
  it { assert_equal("active", visits_p0[:fetch_state]) }
  it { assert_equal(52, visits_p0[:hi_offset]) }
  it { assert_equal(0, visits_p0[:id]) }
  it { assert_equal(0, visits_p0[:lag]) }
  it { assert_equal(0, visits_p0[:lag_d]) }
  it { assert_equal(-1, visits_p0[:lag_stored]) }
  it { assert_equal(0, visits_p0[:lag_stored_d]) }
  it { assert_equal("active", visits_p0[:poll_state]) }
  it { assert_equal(-1_001, visits_p0[:stored_offset]) }

  context "when statistics contain -1 partition" do
    it "excludes -1 partition from partitions_cnt" do
      # Fixture has partitions "0" and "-1" for each topic, so count should be 1
      assert_equal(1, sg_details["sgid"][:topics]["default"][:partitions_cnt])
      assert_equal(1, sg_details["sgid"][:topics]["test2"][:partitions_cnt])
      assert_equal(1, sg_details["sgid"][:topics]["visits"][:partitions_cnt])
    end

    it "does not include -1 partition in partitions hash" do
      refute_includes(sg_details["sgid"][:topics]["default"][:partitions].keys, -1)
      refute_includes(sg_details["sgid"][:topics]["test2"][:partitions].keys, -1)
      refute_includes(sg_details["sgid"][:topics]["visits"][:partitions].keys, -1)
    end
  end
end
