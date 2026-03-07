# frozen_string_literal: true

describe_current do
  let(:pagination) { described_class.new }

  describe "#paginate?" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.paginate? }
    end
  end

  describe "#first_offset?" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.first_offset? }
    end
  end

  describe "#first_offset" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.first_offset }
    end
  end

  describe "#previous_offset?" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.previous_offset? }
    end
  end

  describe "#current_offset?" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.current_offset? }
    end
  end

  describe "#next_offset?" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.next_offset? }
    end
  end

  describe "#offset_key" do
    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { pagination.offset_key }
    end
  end
end
