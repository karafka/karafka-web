# frozen_string_literal: true

describe_current do
  # Minimal broker double exposing the `#id`/`#name` the distribution reads
  def broker(id, name = "broker#{id}")
    Struct.new(:id, :name).new(id, name)
  end

  let(:brokers) { [broker(1), broker(2), broker(3)] }

  let(:topics) do
    [
      {
        topic_name: "orders",
        partitions: [
          { leader: 1, replicas: [1, 2], isrs: [1, 2] },
          { leader: 1, replicas: [1, 3], isrs: [1] },
          { leader: 2, replicas: [2, 3], isrs: [2, 3] }
        ]
      }
    ]
  end

  let(:distribution) { described_class.all(brokers: brokers, topics: topics) }

  # index-aligned with `brokers`
  let(:broker1) { distribution[0] }
  let(:broker2) { distribution[1] }
  let(:broker3) { distribution[2] }

  it "expect to return one row per broker, in the given order" do
    assert_equal(3, distribution.size)
    assert_equal([1, 2, 3], distribution.map(&:broker_id))
    assert_equal(%w[broker1 broker2 broker3], distribution.map(&:broker_name))
  end

  describe "#leader_count" do
    it "expect to count the partitions each broker leads" do
      assert_equal(2, broker1.leader_count)
      assert_equal(1, broker2.leader_count)
      assert_equal(0, broker3.leader_count)
    end
  end

  describe "#replica_count" do
    it "expect to count the partitions each broker replicates" do
      # broker1: p0,p1 | broker2: p0,p2 | broker3: p1,p2
      assert_equal(2, broker1.replica_count)
      assert_equal(2, broker2.replica_count)
      assert_equal(2, broker3.replica_count)
    end
  end

  describe "#leader_share" do
    it "expect to be the broker's share of all partition leaderships (3 total)" do
      assert_in_delta(66.67, broker1.leader_share)
      assert_in_delta(33.33, broker2.leader_share)
      assert_in_delta(0.0, broker3.leader_share)
    end
  end

  describe "#replica_share" do
    it "expect to be the broker's share of all replicas (6 total)" do
      assert_in_delta(33.33, broker1.replica_share)
      assert_in_delta(33.33, broker2.replica_share)
      assert_in_delta(33.33, broker3.replica_share)
    end
  end

  describe "#follower_count" do
    it "expect to count the replicas a broker hosts but does not lead" do
      # broker1 replicates 2 and leads 2 -> 0 followers; broker2 2/1 -> 1; broker3 2/0 -> 2
      assert_equal(0, broker1.follower_count)
      assert_equal(1, broker2.follower_count)
      assert_equal(2, broker3.follower_count)
    end
  end

  describe "#out_of_sync_count" do
    it "expect to count the broker's replicas that are not in the ISR" do
      # broker3 replicates p1 (isrs [1]) and p2 (isrs [2,3]) -> out-of-sync on p1 only
      assert_equal(0, broker1.out_of_sync_count)
      assert_equal(0, broker2.out_of_sync_count)
      assert_equal(1, broker3.out_of_sync_count)
    end

    context "when the ISR data is missing (older metadata)" do
      let(:topics) do
        [{ topic_name: "t", partitions: [{ leader: 1, replicas: [1, 2], isrs: nil }] }]
      end

      it "expect not to crash (treats replicas as out-of-sync)" do
        assert_equal(1, broker1.out_of_sync_count)
        assert_equal(1, broker2.out_of_sync_count)
      end
    end
  end

  context "when a broker leads far more partitions than the others (imbalance is visible)" do
    let(:topics) do
      [
        {
          topic_name: "hot",
          partitions: [
            { leader: 1, replicas: [1] },
            { leader: 1, replicas: [1] },
            { leader: 1, replicas: [1] },
            { leader: 2, replicas: [2] }
          ]
        }
      ]
    end

    it "expect the leader share to expose the imbalance" do
      assert_equal(3, broker1.leader_count)
      assert_in_delta(75.0, broker1.leader_share)
      assert_equal(1, broker2.leader_count)
      assert_in_delta(25.0, broker2.leader_share)
      assert_equal(0, broker3.leader_count)
      assert_in_delta(0.0, broker3.leader_share)
    end
  end

  context "when there are no topics/partitions" do
    let(:topics) { [] }

    it "expect zero counts and zero shares (no division by zero)" do
      assert_equal([0, 0, 0], distribution.map(&:leader_count))
      assert_equal([0, 0, 0], distribution.map(&:replica_count))
      assert_equal([0.0, 0.0, 0.0], distribution.map(&:leader_share))
      assert_equal([0.0, 0.0, 0.0], distribution.map(&:replica_share))
    end

    it "expect no row to be comparable (nothing to distribute), load_ratio 1.0" do
      assert_equal([false, false, false], distribution.map(&:comparable))
      assert_equal([1.0, 1.0, 1.0], distribution.map(&:load_ratio))
    end
  end

  describe "#load_ratio and #comparable" do
    context "when there is more than one broker and partitions to distribute" do
      # 3 brokers -> fair share 33.3%. broker1 leads 66.67% (ratio ~2.0), broker2 33.33% (1.0),
      # broker3 0% (0.0)
      it "expect the load_ratio to be each broker's multiple of its fair share" do
        assert_equal([true, true, true], distribution.map(&:comparable))
        assert_in_delta(2.0, broker1.load_ratio)
        assert_in_delta(1.0, broker2.load_ratio)
        assert_in_delta(0.0, broker3.load_ratio)
      end
    end

    context "when there is a single broker (nothing to compare against)" do
      let(:brokers) { [broker(1)] }
      let(:topics) { [{ topic_name: "t", partitions: [{ leader: 1, replicas: [1] }] }] }

      it "expect it to be not comparable with a neutral load_ratio, even leading everything" do
        assert_in_delta(100.0, broker1.leader_share)
        refute(broker1.comparable)
        assert_in_delta(1.0, broker1.load_ratio)
      end
    end
  end

  describe ".partitions_for" do
    let(:assignments) { described_class.partitions_for(broker_id: 3, topics: topics) }

    it "expect to list only the partitions the broker replicates, with role and ISR state" do
      # broker 3 replicates p1 (isrs [1] -> out of sync) and p2 (isrs [2,3] -> in sync); leads none
      assert_equal(2, assignments.size)
      assert_equal(%w[orders orders], assignments.map(&:topic_name))
      assert_equal(%i[follower follower], assignments.map(&:role))
      assert_equal([false, true], assignments.map(&:in_sync))
    end

    it "expect the leader role for partitions the broker leads" do
      leader_rows = described_class.partitions_for(broker_id: 1, topics: topics)

      assert_equal(%i[leader leader], leader_rows.map(&:role))
    end

    context "when the broker hosts no partitions" do
      it { assert_empty(described_class.partitions_for(broker_id: 999, topics: topics)) }
    end
  end

  context "when a partition has no replicas array (older metadata)" do
    let(:topics) do
      [{ topic_name: "t", partitions: [{ leader: 1, replicas: nil }] }]
    end

    it "expect not to crash and count zero replicas" do
      assert_equal(1, broker1.leader_count)
      assert_equal(0, broker1.replica_count)
    end

    it "expect the derived counts to stay non-negative (no -1 follower/out-of-sync)" do
      assert_equal(0, broker1.follower_count)
      assert_equal(0, broker1.out_of_sync_count)
    end
  end
end
