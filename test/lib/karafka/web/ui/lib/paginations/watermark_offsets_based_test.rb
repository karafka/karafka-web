# frozen_string_literal: true

describe_current do
  let(:current_offset) { 0 }
  let(:low_watermark_offset) { 0 }
  let(:high_watermark_offset) { 0 }

  let(:pagination) do
    described_class.new(
      current_offset,
      low_watermark_offset,
      high_watermark_offset
    )
  end

  it { assert_equal("offset", pagination.offset_key) }

  context "when there is no data in the partition" do
    it { refute_predicate(pagination, :paginate?) }
    it { refute_predicate(pagination, :first_offset?) }
    it { refute_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("0", pagination.current_label) }
    it { refute_predicate(pagination, :next_offset?) }
  end

  context "when we view most recent offset that is also first offset" do
    let(:current_offset) { 0 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 1 }

    it { refute_predicate(pagination, :paginate?) }
    it { refute_predicate(pagination, :first_offset?) }
    it { refute_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("0", pagination.current_label) }
    it { refute_predicate(pagination, :next_offset?) }
  end

  context "when we view most recent distant offset" do
    let(:current_offset) { 99 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_predicate(pagination, :paginate?) }
    it { refute_predicate(pagination, :first_offset?) }
    it { refute_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("99", pagination.current_label) }
    it { assert_predicate(pagination, :next_offset?) }
    it { assert_equal(98, pagination.next_offset) }
  end

  context "when we view most recent distant offset minus one" do
    let(:current_offset) { 98 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_predicate(pagination, :paginate?) }
    it { assert_predicate(pagination, :first_offset?) }
    it { assert_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("98", pagination.current_label) }
    it { assert_predicate(pagination, :next_offset?) }
    it { assert_equal(97, pagination.next_offset) }
    it { assert_equal(99, pagination.previous_offset) }
  end

  context "when we view first but there is a lot" do
    let(:current_offset) { 0 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_predicate(pagination, :paginate?) }
    it { assert_predicate(pagination, :first_offset?) }
    it { assert_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("0", pagination.current_label) }
    it { refute_predicate(pagination, :next_offset?) }
    it { assert_equal(1, pagination.previous_offset) }
  end

  context "when we view second but there is a lot" do
    let(:current_offset) { 1 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_predicate(pagination, :paginate?) }
    it { assert_predicate(pagination, :first_offset?) }
    it { assert_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("1", pagination.current_label) }
    it { assert_predicate(pagination, :next_offset?) }
    it { assert_equal(2, pagination.previous_offset) }
    it { assert_equal(0, pagination.next_offset) }
  end

  context "when we view in the middle" do
    let(:current_offset) { 50 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_predicate(pagination, :paginate?) }
    it { assert_predicate(pagination, :first_offset?) }
    it { assert_predicate(pagination, :previous_offset?) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal("50", pagination.current_label) }
    it { assert_predicate(pagination, :next_offset?) }
    it { assert_equal(51, pagination.previous_offset) }
    it { assert_equal(49, pagination.next_offset) }
  end
end
