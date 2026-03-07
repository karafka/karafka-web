# frozen_string_literal: true

describe_current do
  let(:ttl_array) { described_class.new(100) }

  context "when the array is empty" do
    it { assert_equal([], ttl_array.to_a) }
  end

  context "when we have one element before ttl" do
    before { ttl_array << 1 }

    it { assert_equal([1], ttl_array.to_a) }
  end

  context "when we have pre and post ttl elements" do
    before do
      ttl_array << 1
      sleep(0.1)
      ttl_array << 2
    end

    it { assert_equal([2], ttl_array.to_a) }
  end

  context "when we had only ttled elements" do
    before do
      ttl_array << 1
      sleep(0.1)
    end

    it { assert_empty(ttl_array) }
  end

  context "when testing samples method" do
    it "returns empty array when no elements" do
      assert_equal([], ttl_array.samples)
    end

    it "returns hash with value and added_at for elements within ttl" do
      ttl_array << 1
      samples = ttl_array.samples

      assert_equal(1, samples.size)
      assert_equal(1, samples.first[:value])
      assert_kind_of(Float, samples.first[:added_at])
    end

    it "returns only samples within ttl window" do
      ttl_array << 1
      sleep(0.05)
      ttl_array << 2
      sleep(0.05)

      samples = ttl_array.samples

      assert_equal(1, samples.size)
      assert_equal(2, samples.first[:value])
    end

    it "maintains chronological order of samples" do
      ttl_array << 1
      ttl_array << 2
      ttl_array << 3

      samples = ttl_array.samples

      assert_equal([1, 2, 3], samples.map { |s| s[:value] })
    end
  end

  describe "#inspect" do
    let(:ttl) { 1000 }
    let(:array) { described_class.new(ttl) }

    it "returns correct format for empty array" do
      result = array.inspect

      pattern = /^#<Karafka::Web::Tracking::Helpers::Ttls::Array:0x[0-9a-f]+ ttl=1000ms size=0>$/

      assert_match(pattern, result)
    end

    it "returns correct format with items" do
      array << "item1"
      array << "item2"

      result = array.inspect

      pattern = /^#<Karafka::Web::Tracking::Helpers::Ttls::Array:0x[0-9a-f]+ ttl=1000ms size=2>$/

      assert_match(pattern, result)
    end

    it "shows correct TTL value" do
      custom_array = described_class.new(5000)

      assert_includes(custom_array.inspect, "ttl=5000ms")
    end

    it "shows current size after expired items are cleared" do
      # Add items that will expire
      allow(array).to receive(:monotonic_now).and_return(1000)
      array << "old_item"

      # Time passes beyond TTL
      allow(array).to receive(:monotonic_now).and_return(3000)
      array << "new_item"

      result = array.inspect

      assert_includes(result, "size=1") # Only new_item should remain
    end

    it "includes object_id in hexadecimal format" do
      result = array.inspect
      object_id_hex = format("%#x", array.object_id)

      assert_includes(result, object_id_hex)
    end

    it "calls clear before inspection" do
      allow(array).to receive(:clear).and_call_original
      array.inspect
      expect(array).to have_received(:clear)
    end

    it "handles thread safety during concurrent modifications" do
      errors = []

      writer = Thread.new do
        50.times { |i| array << "item_#{i}" }
      rescue => e
        errors << e
      end

      inspector = Thread.new do
        20.times do
          result = array.inspect

          assert_kind_of(String, result)
          assert_includes(result, "ttl=1000ms")
        end
      rescue => e
        errors << e
      end

      [writer, inspector].each(&:join)

      assert_empty(errors)
    end
  end
end
