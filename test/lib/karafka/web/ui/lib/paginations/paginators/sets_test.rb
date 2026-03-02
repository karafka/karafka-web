# frozen_string_literal: true

describe_current do
  let(:pagination) { described_class.call(counts, page) }

  context "when no data" do
    let(:counts) { [] }

    context "when negative page" do
      let(:page) { -1 }

      it { assert_equal({}, pagination) }
    end

    context "when page 1" do
      let(:page) { 1 }

      it { assert_equal({}, pagination) }
    end

    context "when high page" do
      let(:page) { 1_000_000 }

      it { assert_equal({}, pagination) }
    end
  end

  context "when not enough data and one set" do
    let(:counts) { [5] }

    context "when negative page" do
      let(:page) { -1 }

      it { assert_equal({}, pagination) }
    end

    context "when page 1" do
      let(:page) { 1 }

      it { assert_equal({ 0 => 0..4 }, pagination) }
    end

    context "when high page" do
      let(:page) { 1_000_000 }

      it { assert_equal({}, pagination) }
    end
  end

  context "when not enough data and many sets" do
    let(:counts) { [1, 2, 3, 4, 5] }

    context "when negative page" do
      let(:page) { -1 }

      it { assert_equal({}, pagination) }
    end

    context "when page 1" do
      let(:page) { 1 }

      it { assert_equal({ 0 => 0..0, 1 => 0..1, 2 => 0..2, 3 => 0..3, 4 => 0..4 }, pagination) }
    end

    context "when high page" do
      let(:page) { 1_000_000 }

      it { assert_equal({}, pagination) }
    end
  end

  context "when too many small sets" do
    let(:counts) { Array.new(100) { 1 } }

    context "when negative page" do
      let(:page) { -1 }

      it { assert_equal({}, pagination) }
    end

    context "when page 1" do
      let(:page) { 1 }
      let(:expected) { Array.new(25) { |i| [i, 0..0] }.to_h }

      it { assert_equal(expected, pagination) }
    end

    context "when high page" do
      let(:page) { 1_000_000 }

      it { assert_equal({}, pagination) }
    end
  end

  context "when many sets with different sizes" do
    let(:counts) { [1_000_000, 2, 100, 13, 1_000] }

    context "when negative page" do
      let(:page) { -1 }

      it { assert_equal({}, pagination) }
    end

    context "when page 1" do
      let(:page) { 1 }

      it { assert_equal({ 0 => 0..5, 1 => 0..1, 2 => 0..5, 3 => 0..5, 4 => 0..4 }, pagination) }
    end

    context "when page 2" do
      let(:page) { 2 }

      it { assert_equal({ 0 => 6..11, 2 => 6..11, 3 => 6..11, 4 => 5..11 }, pagination) }
    end

    context "when page 3" do
      let(:page) { 3 }

      it { assert_equal({ 0 => 12..19, 2 => 12..19, 3 => 12..12, 4 => 12..19 }, pagination) }
    end

    context "when high page" do
      let(:page) { 1_000_000 }

      it { assert_equal({}, pagination) }
    end
  end
end
