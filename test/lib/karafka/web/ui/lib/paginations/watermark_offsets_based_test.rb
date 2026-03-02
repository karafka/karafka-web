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
    it { assert_equal(false, pagination.paginate?) }
    it { assert_equal(false, pagination.first_offset?) }
    it { assert_equal(false, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("0", pagination.current_label) }
    it { assert_equal(false, pagination.next_offset?) }
  end

  context "when we view most recent offset that is also first offset" do
    let(:current_offset) { 0 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 1 }

    it { assert_equal(false, pagination.paginate?) }
    it { assert_equal(false, pagination.first_offset?) }
    it { assert_equal(false, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("0", pagination.current_label) }
    it { assert_equal(false, pagination.next_offset?) }
  end

  context "when we view most recent distant offset" do
    let(:current_offset) { 99 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_equal(true, pagination.paginate?) }
    it { assert_equal(false, pagination.first_offset?) }
    it { assert_equal(false, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("99", pagination.current_label) }
    it { assert_equal(true, pagination.next_offset?) }
    it { assert_equal(98, pagination.next_offset) }
  end

  context "when we view most recent distant offset minus one" do
    let(:current_offset) { 98 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_equal(true, pagination.paginate?) }
    it { assert_equal(true, pagination.first_offset?) }
    it { assert_equal(true, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("98", pagination.current_label) }
    it { assert_equal(true, pagination.next_offset?) }
    it { assert_equal(97, pagination.next_offset) }
    it { assert_equal(99, pagination.previous_offset) }
  end

  context "when we view first but there is a lot" do
    let(:current_offset) { 0 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_equal(true, pagination.paginate?) }
    it { assert_equal(true, pagination.first_offset?) }
    it { assert_equal(true, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("0", pagination.current_label) }
    it { assert_equal(false, pagination.next_offset?) }
    it { assert_equal(1, pagination.previous_offset) }
  end

  context "when we view second but there is a lot" do
    let(:current_offset) { 1 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_equal(true, pagination.paginate?) }
    it { assert_equal(true, pagination.first_offset?) }
    it { assert_equal(true, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("1", pagination.current_label) }
    it { assert_equal(true, pagination.next_offset?) }
    it { assert_equal(2, pagination.previous_offset) }
    it { assert_equal(0, pagination.next_offset) }
  end

  context "when we view in the middle" do
    let(:current_offset) { 50 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { assert_equal(true, pagination.paginate?) }
    it { assert_equal(true, pagination.first_offset?) }
    it { assert_equal(true, pagination.previous_offset?) }
    it { assert_equal(true, pagination.current_offset?) }
    it { assert_equal("50", pagination.current_label) }
    it { assert_equal(true, pagination.next_offset?) }
    it { assert_equal(51, pagination.previous_offset) }
    it { assert_equal(49, pagination.next_offset) }
  end
end
