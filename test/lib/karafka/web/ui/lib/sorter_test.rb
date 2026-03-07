# frozen_string_literal: true

describe_current do
  # Simple test class that responds to attribute methods without being Enumerable
  # (unlike Struct which is Enumerable and would interfere with sorter logic)
  let(:sortable_object) do
    Class.new do
      def initialize(attrs)
        @attrs = attrs
        attrs.each do |key, value|
          instance_variable_set("@#{key}", value)
          self.class.define_method(key) { instance_variable_get("@#{key}") }
        end
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        @attrs == other.instance_variable_get(:@attrs)
      end
    end
  end

  let(:sorting) do
    described_class
      .new(sort_query, allowed_attributes: allowed_attributes)
      .call(resource)

    resource
  end

  let(:allowed_attributes) { %w[] }

  context "when we try to sort on something not allowed" do
    let(:resource) { [[1], [2], [3]] }
    let(:sort_query) { "clear desc" }
    let(:allowed_attributes) { %w[] }

    it "does not change the resource" do
      before_val = resource.dup
      sorting

      assert_equal(before_val, resource)
    end
  end

  context "when we sort array of values in an asc order" do
    let(:resource) { [5, 4, 3, 2, 1] }
    let(:sort_query) { "itself asc" }
    let(:allowed_attributes) { %w[itself] }

    it { assert_equal([1, 2, 3, 4, 5], sorting) }
  end

  context "when we sort array of values in an desc order" do
    let(:resource) { [1, 2, 3, 4, 5] }
    let(:sort_query) { "itself desc" }
    let(:allowed_attributes) { %w[itself] }

    it { assert_equal([5, 4, 3, 2, 1], sorting) }
  end

  context "when resource is of not homogeneous type" do
    let(:resource) { [1, 3, 2, true, "test"] }
    let(:sort_query) { "itself desc" }
    let(:allowed_attributes) { %w[itself] }

    it "expect not to sort" do
      assert_equal([1, 3, 2, true, "test"], sorting)
    end
  end

  context "when sorting array of hashes on a symbol key" do
    let(:resource) { [{ a: 2, x: 1 }, { a: 3 }, { a: 7 }] }
    let(:sort_query) { "a desc" }
    let(:allowed_attributes) { %w[a] }

    it { assert_equal([{ a: 7 }, { a: 3 }, { a: 2, x: 1 }], sorting) }
  end

  context "when sorting array of hashes on a string key" do
    let(:resource) { [{ "a" => 2, :x => 1 }, { "a" => 3 }, { "a" => 7 }] }
    let(:sort_query) { "a desc" }
    let(:allowed_attributes) { %w[a] }

    it { assert_equal([{ "a" => 7 }, { "a" => 3 }, { "a" => 2, :x => 1 }], sorting) }
  end

  context "when sorting booleans" do
    let(:resource) { [true, false, true, false] }
    let(:sort_query) { "itself desc" }
    let(:allowed_attributes) { %w[itself] }

    it { assert_equal([true, true, false, false], sorting) }
  end

  context "when sorting objects that respond to an attribute" do
    let(:resource) { [sortable_object.new(a: 5), sortable_object.new(a: 4), sortable_object.new(a: 3)] }
    let(:sort_query) { "a asc" }
    let(:allowed_attributes) { %w[a] }

    it do
      assert_equal([sortable_object.new(a: 3), sortable_object.new(a: 4), sortable_object.new(a: 5)], sorting)
    end
  end

  context "when sorting objects that do not respond to an attribute" do
    let(:resource) { [sortable_object.new(x: 5), sortable_object.new(x: 4), sortable_object.new(x: 3)] }
    let(:sort_query) { "a asc" }
    let(:allowed_attributes) { %w[a] }

    it "does not change the resource" do
      before_val = resource.dup
      sorting

      assert_equal(before_val, resource)
    end
  end
end
