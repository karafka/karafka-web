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
          { leader: 1, replicas: [1, 2] },
          { leader: 1, replicas: [1, 3] },
          { leader: 2, replicas: [2, 3] }
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

    it "expect every broker to be balanced (nothing to distribute)" do
      assert_equal(%i[balanced balanced balanced], distribution.map(&:imbalance))
    end
  end

  describe "#imbalance" do
    context "when leaderships are spread evenly" do
      let(:topics) do
        [{ topic_name: "t", partitions: [
          { leader: 1, replicas: [1] },
          { leader: 2, replicas: [2] },
          { leader: 3, replicas: [3] }
        ] }]
      end

      it { assert_equal(%i[balanced balanced balanced], distribution.map(&:imbalance)) }
    end

    context "when one broker leads far more and another far fewer than the fair share" do
      # 3 brokers -> fair share 33.3%. broker1 leads 3/4 (75% > 50%) -> overloaded,
      # broker2 leads 1/4 (25%) -> balanced, broker3 leads 0% (< 16.6%) -> underloaded
      let(:topics) do
        [{ topic_name: "hot", partitions: [
          { leader: 1, replicas: [1] },
          { leader: 1, replicas: [1] },
          { leader: 1, replicas: [1] },
          { leader: 2, replicas: [2] }
        ] }]
      end

      it "expect to flag the overloaded and underloaded brokers" do
        assert_equal(:overloaded, broker1.imbalance)
        assert_equal(:balanced, broker2.imbalance)
        assert_equal(:underloaded, broker3.imbalance)
      end
    end

    context "when there is a single broker (nothing to compare against)" do
      let(:brokers) { [broker(1)] }
      let(:topics) { [{ topic_name: "t", partitions: [{ leader: 1, replicas: [1] }] }] }

      it "expect it to be balanced even though it leads everything" do
        assert_in_delta(100.0, broker1.leader_share)
        assert_equal(:balanced, broker1.imbalance)
      end
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
  end
end
