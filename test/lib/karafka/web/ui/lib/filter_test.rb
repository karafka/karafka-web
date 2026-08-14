# frozen_string_literal: true

describe_current do
  # Simple record class that responds to attribute methods without being Enumerable, mirroring
  # the objects (processes, topics, jobs) we filter in the UI
  let(:record_class) do
    Class.new do
      def initialize(attrs)
        @attrs = attrs
        attrs.each do |key, value|
          instance_variable_set("@#{key}", value)
          unless self.class.method_defined?(key)
            self.class.define_method(key) { instance_variable_get("@#{key}") }
          end
        end
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        @attrs == other.instance_variable_get(:@attrs)
      end
    end
  end

  let(:filtering) do
    described_class
      .new(filter_query, allowed_attributes: allowed_attributes)
      .call(resource)
  end

  let(:allowed_attributes) { %w[] }

  context "when the query is empty" do
    let(:resource) { [{ "name" => "a" }, { "name" => "b" }] }
    let(:filter_query) { "" }
    let(:allowed_attributes) { %w[name] }

    it "does not change the resource" do
      before_val = resource.dup

      assert_equal(before_val, filtering)
    end
  end

  context "when the query is only whitespace" do
    let(:resource) { [{ "name" => "a" }, { "name" => "b" }] }
    let(:filter_query) { "   " }
    let(:allowed_attributes) { %w[name] }

    it "does not change the resource" do
      before_val = resource.dup

      assert_equal(before_val, filtering)
    end
  end

  context "when filtering an array of hashes on a string key" do
    let(:resource) do
      [
        { "name" => "orders" },
        { "name" => "payments" },
        { "name" => "shipping" }
      ]
    end
    let(:filter_query) { "pay" }
    let(:allowed_attributes) { %w[name] }

    it "keeps only matching elements" do
      assert_equal([{ "name" => "payments" }], filtering)
    end
  end

  context "when filtering an array of hashes on a symbol key" do
    let(:resource) { [{ name: "orders" }, { name: "payments" }] }
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[name] }

    it "keeps only matching elements" do
      assert_equal([{ name: "orders" }], filtering)
    end
  end

  context "when the match is case-insensitive" do
    let(:resource) { [{ "name" => "OrDeRs" }, { "name" => "payments" }] }
    let(:filter_query) { "ORDE" }
    let(:allowed_attributes) { %w[name] }

    it "still matches" do
      assert_equal([{ "name" => "OrDeRs" }], filtering)
    end
  end

  context "when the attribute is not allowed" do
    let(:resource) { [{ "name" => "orders" }, { "name" => "payments" }] }
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[] }

    it "does not filter anything out" do
      before_val = resource.dup

      assert_equal(before_val, filtering)
    end
  end

  context "when filtering an array of records responding to attributes" do
    let(:resource) do
      [
        record_class.new(id: "consumer-1", host: "web-01"),
        record_class.new(id: "consumer-2", host: "web-02")
      ]
    end
    let(:filter_query) { "web-02" }
    let(:allowed_attributes) { %w[id host] }

    it "keeps only the matching record" do
      result = filtering

      assert_equal(1, result.size)
      assert_equal("consumer-2", result.first.id)
    end
  end

  context "when the query matches on one of several allowed attributes" do
    let(:resource) do
      [
        record_class.new(id: "aaa", type: "consumer"),
        record_class.new(id: "bbb", type: "producer")
      ]
    end
    let(:filter_query) { "produc" }
    let(:allowed_attributes) { %w[id type] }

    it "keeps the record matching on any attribute" do
      result = filtering

      assert_equal(%w[bbb], result.map(&:id))
    end
  end

  context "when filtering an array of non-matchable scalars" do
    let(:resource) { [1, 2, 3] }
    let(:filter_query) { "2" }
    let(:allowed_attributes) { %w[name] }

    it "leaves the array untouched" do
      assert_equal([1, 2, 3], filtering)
    end
  end

  context "when nothing matches in an array" do
    let(:resource) { [{ "name" => "orders" }, { "name" => "payments" }] }
    let(:filter_query) { "nope" }
    let(:allowed_attributes) { %w[name] }

    it "returns an empty array" do
      assert_equal([], filtering)
    end
  end

  context "when filtering a nested hash by a key (health-like structure)" do
    let(:resource) do
      {
        "consumer_group_a" => {
          "orders" => { 0 => { "lag" => 1 }, 1 => { "lag" => 2 } },
          "payments" => { 0 => { "lag" => 5 } }
        },
        "consumer_group_b" => {
          "shipping" => { 0 => { "lag" => 9 } }
        }
      }
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[lag] }

    it "keeps only the branch under the matching key and drops the rest" do
      result = filtering

      assert_equal(%w[consumer_group_a], result.keys)
      assert_equal(%w[orders], result["consumer_group_a"].keys)
      # The whole matching topic subtree is preserved untouched
      assert_equal({ 0 => { "lag" => 1 }, 1 => { "lag" => 2 } }, result["consumer_group_a"]["orders"])
    end
  end

  context "when a parent key matches (match-propagation keeps all children)" do
    let(:resource) do
      {
        "consumer_group_a" => {
          "orders" => { 0 => { "lag" => 1 } },
          "payments" => { 0 => { "lag" => 5 } }
        }
      }
    end
    let(:filter_query) { "consumer_group_a" }
    let(:allowed_attributes) { %w[lag] }

    it "keeps the whole subtree" do
      result = filtering

      assert_equal(%w[orders payments], result["consumer_group_a"].keys)
    end
  end

  context "when matching on a leaf record attribute deep in a hash" do
    let(:resource) do
      {
        "consumer_group_a" => {
          "orders" => [
            record_class.new(id: "partition-0", state: "active"),
            record_class.new(id: "partition-1", state: "paused")
          ],
          "payments" => [
            record_class.new(id: "partition-0", state: "active")
          ]
        }
      }
    end
    let(:filter_query) { "paused" }
    let(:allowed_attributes) { %w[id state] }

    it "keeps only the branches that contain a matching leaf" do
      result = filtering

      assert_equal(%w[orders], result["consumer_group_a"].keys)
      assert_equal(%w[partition-1], result["consumer_group_a"]["orders"].map(&:id))
    end
  end

  context "when a structural hash mixes nested collections with scalar metadata" do
    let(:resource) do
      {
        "consumer_group_a" => {
          rebalanced_at: 123_456,
          topics: {
            "orders" => {
              partitions_count: 10,
              partitions: { 0 => record_class.new(id: "0", state: "active") }
            },
            "payments" => {
              partitions_count: 3,
              partitions: { 0 => record_class.new(id: "0", state: "paused") }
            }
          }
        }
      }
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[id state] }

    it "keeps the matching branch together with its scalar metadata and drops the rest" do
      result = filtering
      topics = result["consumer_group_a"][:topics]

      # Sibling metadata of kept branches is preserved
      assert_equal(123_456, result["consumer_group_a"][:rebalanced_at])
      assert_equal(%w[orders], topics.keys.map(&:to_s))
      assert_equal(10, topics["orders"][:partitions_count])
      assert_equal(1, topics["orders"][:partitions].size)
    end
  end

  context "when a structural hash holds a non-matchable set of scalars as metadata" do
    let(:resource) do
      {
        "consumer_group_a" => {
          rebalance_ages: Set.new([100, 200]),
          topics: {
            "orders" => { partitions: { 0 => record_class.new(id: "0", state: "active") } },
            "payments" => { partitions: { 0 => record_class.new(id: "0", state: "active") } }
          }
        }
      }
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[id state] }

    it "retains the set metadata while still pruning the non-matching topics" do
      result = filtering
      cg = result["consumer_group_a"]

      assert_equal(Set.new([100, 200]), cg[:rebalance_ages])
      assert_equal(%w[orders], cg[:topics].keys.map(&:to_s))
    end
  end

  context "when filtering a custom enumerable collection that supports select!" do
    # Mirrors the `Jobs` model: an Enumerable wrapper delegating select! to an inner array
    let(:collection_class) do
      Class.new do
        include Enumerable
        extend Forwardable

        def_delegators :@items, :select!, :any?, :size, :empty?

        def initialize(items)
          @items = items
        end

        def each(&) = @items.each(&)
      end
    end

    let(:resource) do
      collection_class.new(
        [
          record_class.new(topic: "orders", type: "consume"),
          record_class.new(topic: "payments", type: "consume")
        ]
      )
    end
    let(:filter_query) { "payments" }
    let(:allowed_attributes) { %w[topic type] }

    it "prunes the collection in place" do
      filtering

      assert_equal(1, resource.size)
      assert_equal(%w[payments], resource.map(&:topic))
    end
  end

  context "when filtering a hash proxy backed array" do
    let(:resource) do
      [
        Karafka::Web::Ui::Lib::HashProxy.new(id: "proc-1", name: "billing"),
        Karafka::Web::Ui::Lib::HashProxy.new(id: "proc-2", name: "orders")
      ]
    end
    let(:filter_query) { "billing" }
    let(:allowed_attributes) { %w[id name] }

    it "keeps only the matching proxy" do
      result = filtering

      assert_equal(1, result.size)
      assert_equal("proc-1", result.first.id)
    end
  end

  context "when the structure contains a circular reference" do
    let(:resource) do
      a = { "name" => "orders" }
      a["self"] = a
      [a]
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[name] }

    it "does not crash and keeps the matching element" do
      result = filtering

      assert_equal(1, result.size)
    end
  end

  context "when allowed_attributes is a label hash" do
    let(:resource) { [{ "name" => "orders" }, { "name" => "payments" }] }
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { { "name" => "Name" } }

    it "uses the hash keys as the allowed attributes" do
      assert_equal([{ "name" => "orders" }], filtering)
    end
  end

  context "when an attribute is multi-valued (array)" do
    let(:resource) do
      [
        record_class.new(id: "a", topics: %w[orders shipments]),
        record_class.new(id: "b", topics: %w[payments])
      ]
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[topics] }

    it "matches when any element of the array includes the query" do
      result = filtering

      assert_equal(%w[a], result.map(&:id))
    end
  end

  context "when a matched attribute value is a present false" do
    let(:resource) do
      [
        record_class.new(name: "orders", active: true),
        record_class.new(name: "payments", active: false)
      ]
    end
    let(:filter_query) { "false" }
    let(:allowed_attributes) { %w[active] }

    it "treats false as a real (matchable) value, not an absent attribute" do
      result = filtering

      assert_equal(%w[payments], result.map(&:name))
    end
  end

  context "when a matched attribute is present but nil on the non-matching records" do
    let(:resource) do
      [
        record_class.new(name: "orders"),
        record_class.new(name: nil)
      ]
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[name] }

    it "still prunes the present-but-nil record (it is actionable, not metadata)" do
      result = filtering

      assert_equal(1, result.size)
      assert_equal("orders", result.first.name)
    end
  end

  context "when matching on a numeric attribute value" do
    let(:resource) do
      [
        record_class.new(name: "a", port: 9092),
        record_class.new(name: "b", port: 9093)
      ]
    end
    let(:filter_query) { "9092" }
    let(:allowed_attributes) { %w[port] }

    it "matches on the stringified number" do
      result = filtering

      assert_equal(%w[a], result.map(&:name))
    end
  end

  context "when a matching record hash also carries nested children" do
    let(:resource) do
      [
        { "name" => "orders", "config" => { "x" => { "y" => 1 } } },
        { "name" => "payments", "config" => { "x" => { "y" => 2 } } }
      ]
    end
    let(:filter_query) { "orders" }
    let(:allowed_attributes) { %w[name] }

    it "keeps the matching record whole (its children are not pruned) and drops the rest" do
      result = filtering

      assert_equal(1, result.size)
      assert_equal({ "x" => { "y" => 1 } }, result.first["config"])
    end
  end

  context "when the query has surrounding whitespace" do
    let(:resource) { [{ "name" => "orders" }, { "name" => "payments" }] }
    let(:filter_query) { "  orders  " }
    let(:allowed_attributes) { %w[name] }

    it "strips the query before matching" do
      assert_equal([{ "name" => "orders" }], filtering)
    end
  end

  context "when the structure is nested deeper than the max depth" do
    let(:resource) do
      # A single non-matching record buried far below the MAX_DEPTH (8) cutoff
      nested = { "topics" => { "orders" => record_class.new(id: "x", state: "active") } }
      12.times { |i| nested = { "level_#{i}" => nested } }
      nested
    end
    let(:filter_query) { "zzz-no-match" }
    let(:allowed_attributes) { %w[id state] }

    it "retains data beyond the max depth instead of pruning it" do
      # Nothing matches the query, so without the depth guard the whole tree would collapse to {}.
      # Because part of it lives below MAX_DEPTH we refuse to look that deep and keep it.
      refute_empty(filtering)
    end
  end

  context "when filtering is scoped to a specific field" do
    let(:resource) do
      [
        record_class.new(id: "aaa", topic: "orders"),
        record_class.new(id: "orders", topic: "payments")
      ]
    end
    let(:allowed_attributes) { { "id" => "ID", "topic" => "Topic" } }

    it "matches only on the selected field" do
      result = described_class
        .new("orders", allowed_attributes: allowed_attributes, field: "topic")
        .call(resource)

      # Only the record whose *topic* is orders is kept; the one whose id is "orders" is excluded
      assert_equal(%w[aaa], result.map(&:id))
    end

    it "falls back to matching all attributes when the field is not allowed" do
      result = described_class
        .new("orders", allowed_attributes: allowed_attributes, field: "not_allowed")
        .call(resource)

      # Both are kept: one matches on topic, the other on id
      assert_equal(%w[aaa orders], result.map(&:id).sort)
    end
  end

  # A key alias matches nested hash KEYS at a path (used for tree data whose labels are keys, like
  # the health stats). Duck-typed via `name`/`path`, so we use a bare Struct here.
  describe "key alias fields" do
    let(:key_field) { Struct.new(:name, :path) }

    context "when scoping to a root-level key alias" do
      let(:resource) do
        {
          "group_a" => { "orders" => { 0 => { "lag" => 1 } } },
          "group_b" => { "payments" => { 0 => { "lag" => 2 } } }
        }
      end

      it "keeps only the matching top-level branch, untouched" do
        field = key_field.new("consumer_group", [])
        result = described_class
          .new("group_a", allowed_attributes: [field], field: "consumer_group")
          .call(resource)

        assert_equal(%w[group_a], result.keys)
        assert_equal({ "orders" => { 0 => { "lag" => 1 } } }, result["group_a"])
      end
    end

    context "when scoping to a nested key alias (topics wrapped under :topics)" do
      let(:resource) do
        {
          "group_a" => {
            topics: {
              "orders" => { 0 => { "lag" => 1 } },
              "payments" => { 0 => { "lag" => 2 } }
            },
            rebalanced_at: 123
          }
        }
      end

      it "prunes the topic keys under :topics and keeps the group via propagation" do
        field = key_field.new("topic", %i[topics])
        result = described_class
          .new("orders", allowed_attributes: [field], field: "topic")
          .call(resource)

        assert_equal(%w[group_a], result.keys)
        assert_equal(%w[orders], result["group_a"][:topics].keys)
      end
    end

    context "when the same nested key alias meets a differently-shaped tree (lenient descent)" do
      let(:resource) do
        {
          "group_a" => {
            "orders" => [{ id: "0" }],
            "payments" => [{ id: "0" }]
          }
        }
      end

      it "falls back to the container itself when :topics is absent and still prunes topics" do
        field = key_field.new("topic", %i[topics])
        result = described_class
          .new("orders", allowed_attributes: [field], field: "topic")
          .call(resource)

        assert_equal(%w[orders], result["group_a"].keys)
      end
    end

    context "when nothing matches a key alias" do
      let(:resource) { { "group_a" => { "orders" => { 0 => {} } } } }

      it "prunes everything" do
        field = key_field.new("consumer_group", [])
        result = described_class
          .new("zzz-nope", allowed_attributes: [field], field: "consumer_group")
          .call(resource)

        assert_empty(result)
      end
    end
  end
end
