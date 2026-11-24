# frozen_string_literal: true

describe_current do
  describe ".all" do
    let(:result) { described_class.all }

    before do
      Karafka::Admin.stubs(:read_lags_with_offsets).returns(
        "zeta" => {
          "orders" => { 1 => { lag: 5, offset: 10 } }
        },
        "alpha" => {
          "visits" => { 0 => { lag: 1, offset: 2 } },
          "default" => { 0 => { lag: 3, offset: 4 } }
        }
      )
    end

    it "expect to remap raw results into id/lag/stored_offset partition hashes" do
      assert_equal([{ id: 1, lag: 5, stored_offset: 10 }], result["zeta"]["orders"])
    end

    it "expect consumer groups and their topics to be alphabetically ordered" do
      assert_equal(%w[alpha zeta], result.keys)
      assert_equal(%w[default visits], result["alpha"].keys)
    end

    context "when Kafka reports a topic's partitions out of order" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).returns(
          "alpha" => {
            "orders" => {
              2 => { lag: 30, offset: 300 },
              0 => { lag: 10, offset: 100 },
              10 => { lag: 40, offset: 400 },
              1 => { lag: 20, offset: 200 }
            }
          }
        )
      end

      it "expect partitions to be ordered by id" do
        assert_equal([0, 1, 2, 10], result["alpha"]["orders"].map { |partition| partition[:id] })
      end

      # The report-based tree keeps partitions in an id-keyed Hash, but this lens keeps them in an
      # Array that ClusterLagsAggregation and the partitions controller both consume - so ordering
      # must not change the shape.
      it "expect partitions to remain an array of id/lag/stored_offset hashes" do
        partitions = result["alpha"]["orders"]

        assert_instance_of(Array, partitions)
        assert_equal({ id: 0, lag: 10, stored_offset: 100 }, partitions.first)
      end
    end
  end

  describe ".partition" do
    it "expect to remap the Kafka lag and offset into id/lag/stored_offset" do
      assert_equal(
        { id: 3, lag: 7, stored_offset: 12 },
        described_class.partition(3, { lag: 7, offset: 12 })
      )
    end
  end
end
