# frozen_string_literal: true

describe_current do
  let(:pagination) { described_class.call(array, page) }

  context "when a bit of data and page 1" do
    let(:array) { [1, 2, 3] }
    let(:page) { 1 }

    it { assert_equal([1, 2, 3], pagination[0]) }
    it { assert_equal(true, pagination[1]) }
  end

  context "when a lot of data and page 1" do
    let(:array) { (0..100).to_a }
    let(:page) { 1 }

    it { assert_equal((0..24).to_a, pagination[0]) }
    it { assert_equal(false, pagination[1]) }
  end

  context "when a lot of data and last page" do
    let(:array) { (0..110).to_a }
    let(:page) { 5 }

    it { assert_equal((100..110).to_a, pagination[0]) }
    it { assert_equal(true, pagination[1]) }
  end

  context "when no data and page 1" do
    let(:array) { [] }
    let(:page) { 1 }

    it { assert_equal([], pagination[0]) }
    it { assert_equal(true, pagination[1]) }
  end

  context "when no data and page 2" do
    let(:array) { [] }
    let(:page) { 2 }

    it { assert_equal([], pagination[0]) }
    it { assert_equal(true, pagination[1]) }
  end
end
