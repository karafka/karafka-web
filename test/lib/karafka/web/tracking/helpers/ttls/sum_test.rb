# frozen_string_literal: true

describe_current do
  let(:ttl_sum) { described_class.new(1_000) }

  def at(now)
    ttl_sum.stubs(:monotonic_now).returns(now)
  end

  context "when nothing was added" do
    it { assert_empty(ttl_sum) }
    it { assert_equal(0, ttl_sum.sum) }
  end

  context "when adding a value" do
    before { at(10_100.0) }

    it { assert_equal(5, ttl_sum << 5) }
  end

  context "when values are added within the same second" do
    before do
      at(10_100.0)
      ttl_sum << 1
      at(10_999.0)
      ttl_sum << 2.5
    end

    it { assert_in_delta(3.5, ttl_sum.sum) }
    it { refute_empty(ttl_sum) }

    it "expires them together" do
      at(12_000.0)

      assert_in_delta(3.5, ttl_sum.sum)

      at(12_001.0)

      assert_empty(ttl_sum)
      assert_equal(0, ttl_sum.sum)
    end
  end

  context "when values are added in different seconds" do
    before do
      at(10_900.0)
      ttl_sum << 1
      at(11_100.0)
      ttl_sum << 2
    end

    it { assert_equal(3, ttl_sum.sum) }

    it "keeps the older second until its newest possible value is older than the ttl" do
      at(12_000.0)

      assert_equal(3, ttl_sum.sum)
    end

    it "expires the older second first" do
      at(12_001.0)

      assert_equal(2, ttl_sum.sum)
    end

    it "expires all of them once the newest second is older than the ttl" do
      at(13_001.0)

      assert_empty(ttl_sum)
    end

    it "expires the old seconds when a new value is added" do
      at(20_000.0)
      ttl_sum << 7

      assert_equal(7, ttl_sum.sum)
    end
  end

  context "when using the real clock" do
    let(:ttl_sum) { described_class.new(100) }

    before do
      ttl_sum << 1
      sleep(1.2)
    end

    it { assert_empty(ttl_sum) }
  end
end
