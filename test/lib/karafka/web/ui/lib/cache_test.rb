# frozen_string_literal: true

describe_current do
  let(:cache) { described_class.new(ttl_ms) }

  let(:ttl_ms) { 200 }

  describe "#fetch" do
    context "when key is not cached yet" do
      it "computes and caches the value" do
        value = cache.fetch(:foo) { "bar" }

        assert_equal("bar", value)
        assert(cache.exist?)
      end
    end

    context "when key is already cached" do
      before { cache.fetch(:foo) { "first" } }

      it "returns the cached value without recomputing" do
        result = cache.fetch(:foo) { "second" }

        assert_equal("first", result)
      end
    end

    it "updates the hash after fetching a new key" do
      before_val = cache.hash
      cache.fetch(:foo) { "bar" }
      refute_equal(before_val, cache.hash)
    end
  end

  describe "#exist?" do
    it "returns false before any fetch" do
      refute(cache.exist?)
    end

    it "returns true after a fetch" do
      cache.fetch(:foo) { 1 }

      assert(cache.exist?)
    end
  end

  describe "#timestamp" do
    it "returns nil initially" do
      assert_nil(cache.timestamp)
    end

    it "returns a Unix timestamp after fetch" do
      cache.fetch(:foo) { 123 }

      assert_kind_of(Numeric, cache.timestamp)
    end
  end

  describe "#hash" do
    it "returns nil initially" do
      assert_nil(cache.hash)
    end

    it "returns a SHA256 digest after fetch" do
      cache.fetch(:a) { 1 }

      assert_match(/\A\h{64}\z/, cache.hash)
    end
  end

  describe "#clear" do
    before { cache.fetch(:foo) { "bar" } }

    it "clears values and metadata" do
      cache.clear

      refute(cache.exist?)
      assert_nil(cache.timestamp)
      assert_nil(cache.hash)
    end
  end

  describe "#clear_if_needed" do
    let(:ts) { Time.now.to_i }

    context "when session hash and timestamp match current state" do
      it "does not clear the cache" do
        value = cache.fetch(:foo) { "bar" }
        result = cache.clear_if_needed(cache.hash, cache.timestamp)

        assert_nil(result)
        assert_equal(value, cache.fetch(:foo) { "new" })
      end
    end

    context "when session timestamp is newer" do
      it "clears the cache" do
        cache.fetch(:foo) { "old" }
        assert_nil(cache.clear_if_needed("other", cache.timestamp + 10))

        refute(cache.exist?)
      end
    end

    context "when cache TTL is exceeded" do
      it "clears the cache" do
        freeze_time = Time.now
        Time.stubs(:now).returns(freeze_time)

        cache.fetch(:foo) { "data" }
        initial_ts = cache.timestamp

        # Simulate time passing beyond TTL
        later = freeze_time + ((ttl_ms + 50) / 1000.0)
        Time.stubs(:now).returns(later)

        cache.clear_if_needed(cache.hash, initial_ts)

        refute(cache.exist?)
      end
    end

    context "when session hash is nil" do
      it "clears the cache" do
        cache.fetch(:foo) { 123 }
        cache.clear_if_needed(nil, cache.timestamp)

        refute(cache.exist?)
      end
    end

    context "when session timestamp is nil" do
      it "clears the cache" do
        cache.fetch(:foo) { 123 }
        cache.clear_if_needed(cache.hash, nil)

        refute(cache.exist?)
      end
    end
  end
end
