# frozen_string_literal: true

describe_current do
  let(:aggregated) { described_class.new(partitions) }

  def partition(id, lag:, stored_offset: 0)
    { id: id, lag: lag, stored_offset: stored_offset }
  end

  describe "#partitions_count" do
    let(:partitions) { [partition(0, lag: 1), partition(1, lag: 2)] }

    it { assert_equal(2, aggregated.partitions_count) }
  end

  describe "#lag" do
    context "when partitions have lag" do
      let(:partitions) { [partition(0, lag: 100), partition(1, lag: 900)] }

      it "expect to sum the lags" do
        assert_equal(1_000, aggregated.lag)
      end
    end

    context "when a partition was never consumed (negative lag)" do
      let(:partitions) { [partition(0, lag: 100), partition(1, lag: -1)] }

      it "expect to exclude it from the sum" do
        assert_equal(100, aggregated.lag)
      end
    end

    context "when no partition was consumed" do
      let(:partitions) { [partition(0, lag: -1)] }

      it "expect to return -1 (N/A)" do
        assert_equal(-1, aggregated.lag)
      end
    end
  end

  describe "#max_lag and #max_lag_partition_id" do
    let(:partitions) do
      [
        partition(0, lag: 100),
        partition(1, lag: 9_000),
        partition(2, lag: 50)
      ]
    end

    it "expect to expose the biggest single-partition lag and its id" do
      assert_equal(9_000, aggregated.max_lag)
      assert_equal(1, aggregated.max_lag_partition_id)
    end

    context "when no partition was consumed" do
      let(:partitions) { [partition(0, lag: -1)] }

      it "expect the -1 sentinels (never nil)" do
        assert_equal(-1, aggregated.max_lag)
        assert_equal(-1, aggregated.max_lag_partition_id)
      end
    end
  end

  describe "#avg_lag" do
    let(:partitions) { [partition(0, lag: 100), partition(1, lag: 900)] }

    it { assert_equal(500, aggregated.avg_lag) }
  end

  describe "#skewed?" do
    context "when the lag is evenly spread" do
      let(:partitions) do
        [partition(0, lag: 1_000), partition(1, lag: 1_000), partition(2, lag: 1_000)]
      end

      it { refute(aggregated.skewed?) }
    end

    context "when the lag is concentrated on one partition" do
      let(:partitions) do
        [
          partition(0, lag: 9_100),
          partition(1, lag: 300),
          partition(2, lag: 300),
          partition(3, lag: 300)
        ]
      end

      it { assert(aggregated.skewed?) }
    end
  end
end
