# frozen_string_literal: true

describe_current do
  describe "#call" do
    it "stringifies keys of a flat hash" do
      assert_equal(
        { "a" => 1, "b" => 2 },
        described_class.call(a: 1, b: 2)
      )
    end

    it "joins nested hash keys with dots" do
      assert_equal(
        { "a.b" => 1 },
        described_class.call(a: { b: 1 })
      )
    end

    it "flattens arbitrarily deep nesting" do
      assert_equal(
        { "a.b.c.d" => 5 },
        described_class.call(a: { b: { c: { d: 5 } } })
      )
    end

    it "indexes array values by their position" do
      assert_equal(
        { "a.0" => 10, "a.1" => 20 },
        described_class.call(a: [10, 20])
      )
    end

    it "recurses into arrays of hashes" do
      assert_equal(
        { "a.0.x" => 1, "a.1.y" => 2 },
        described_class.call(a: [{ x: 1 }, { y: 2 }])
      )
    end

    it "prefixes every key when a prefix is given" do
      assert_equal(
        { "kafka.b" => 1 },
        described_class.call({ b: 1 }, "kafka")
      )
    end

    it "keeps present nil and false leaf values" do
      assert_equal(
        { "a" => nil, "b" => false },
        described_class.call(a: nil, b: false)
      )
    end

    it "mixes scalars, nested hashes and arrays in one pass" do
      assert_equal(
        { "kafka.host" => "localhost", "kafka.brokers.0" => "b1", "topic.name" => "orders" },
        described_class.call(
          kafka: { host: "localhost", brokers: ["b1"] },
          topic: { name: "orders" }
        )
      )
    end

    it "returns an empty hash for an empty hash" do
      assert_empty(described_class.call({}))
    end
  end
end
