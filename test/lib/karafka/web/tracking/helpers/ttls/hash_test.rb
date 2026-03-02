# frozen_string_literal: true

describe_current do
  let(:ttl_hash) { described_class.new(100) }

  context "when we add data into the hash" do
    before { ttl_hash[:test] << 1 }

    it { assert_equal([1], ttl_hash[:test].to_a) }

    context "when enough time has passed" do
      before { sleep(0.1) }

      it { assert_equal([], ttl_hash[:test].to_a) }
    end
  end

  context "when running inspect while extending hash data" do
    let(:ttl_hash) { described_class.new(5000) }

    it "safely handles inspect during concurrent modifications" do
      errors = []

      writer = Thread.new do
        20.times { |i| ttl_hash["key_#{i}"] << [i, Time.now.to_f * 1000] }
      rescue => e
        errors << e
      end

      inspector = Thread.new do
        10.times { assert_includes(ttl_hash.inspect, "Ttls::Hash") }
      rescue => e
        errors << e
      end

      [writer, inspector].each(&:join)
      assert_empty(errors)
    end
  end
end
