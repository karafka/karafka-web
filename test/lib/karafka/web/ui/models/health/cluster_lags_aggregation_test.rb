# frozen_string_literal: true

describe_current do
  let(:aggregated) { described_class.call }

  before do
    Karafka::Admin.stubs(:read_lags_with_offsets).returns(
      "app" => {
        "orders" => {
          0 => { lag: 100, offset: 5 },
          1 => { lag: 900, offset: 10 }
        }
      }
    )
  end

  it "expect to collapse each topic into an AggregatedClusterTopic summary" do
    topic_stats = aggregated["app"]["orders"]

    assert_instance_of(Karafka::Web::Ui::Models::Health::AggregatedClusterTopic, topic_stats)
    assert_equal(2, topic_stats.partitions_count)
    assert_equal(1_000, topic_stats.lag)
    assert_equal(900, topic_stats.max_lag)
    assert_equal(1, topic_stats.max_lag_partition_id)
    assert_equal(500, topic_stats.avg_lag)
  end

  context "when the cluster reports groups and topics out of order" do
    before do
      Karafka::Admin.stubs(:read_lags_with_offsets).returns(
        "zeta" => {
          "orders" => { 0 => { lag: 1, offset: 1 } }
        },
        "alpha" => {
          "visits" => { 0 => { lag: 1, offset: 1 } },
          "default" => { 0 => { lag: 1, offset: 1 } }
        }
      )
    end

    it "expect consumer groups and topics to be alphabetically ordered (like the topics view)" do
      assert_equal(%w[alpha zeta], aggregated.keys)
      assert_equal(%w[default visits], aggregated["alpha"].keys)
    end
  end
end
