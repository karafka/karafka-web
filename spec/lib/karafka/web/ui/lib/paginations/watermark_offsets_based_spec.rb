# frozen_string_literal: true

RSpec.describe_current do
  let(:current_offset) { 0 }
  let(:low_watermark_offset) { 0 }
  let(:high_watermark_offset) { 0 }

  subject(:pagination) do
    described_class.new(
      current_offset,
      low_watermark_offset,
      high_watermark_offset
    )
  end

  it { expect(pagination.offset_key).to eq('offset') }

  context 'when there is no data in the partition' do
    it { expect(pagination.paginate?).to be(false) }
    it { expect(pagination.first_offset?).to be(false) }
    it { expect(pagination.previous_offset?).to be(false) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('0') }
    it { expect(pagination.next_offset?).to be(false) }
  end

  context 'when we view most recent offset that is also first offset' do
    let(:current_offset) { 0 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 1 }

    it { expect(pagination.paginate?).to be(false) }
    it { expect(pagination.first_offset?).to be(false) }
    it { expect(pagination.previous_offset?).to be(false) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('0') }
    it { expect(pagination.next_offset?).to be(false) }
  end

  context 'when we view most recent distant offset' do
    let(:current_offset) { 99 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(false) }
    it { expect(pagination.previous_offset?).to be(false) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('99') }
    it { expect(pagination.next_offset?).to be(true) }
    it { expect(pagination.next_offset).to eq(98) }
  end

  context 'when we view most recent distant offset minus one' do
    let(:current_offset) { 98 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(true) }
    it { expect(pagination.previous_offset?).to be(true) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('98') }
    it { expect(pagination.next_offset?).to be(true) }
    it { expect(pagination.next_offset).to eq(97) }
    it { expect(pagination.previous_offset).to eq(99) }
  end

  context 'when we view first but there is a lot' do
    let(:current_offset) { 0 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(true) }
    it { expect(pagination.previous_offset?).to be(true) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('0') }
    it { expect(pagination.next_offset?).to be(false) }
    it { expect(pagination.previous_offset).to eq(1) }
  end

  context 'when we view second but there is a lot' do
    let(:current_offset) { 1 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(true) }
    it { expect(pagination.previous_offset?).to be(true) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('1') }
    it { expect(pagination.next_offset?).to be(true) }
    it { expect(pagination.previous_offset).to eq(2) }
    it { expect(pagination.next_offset).to eq(0) }
  end

  context 'when we view in the middle' do
    let(:current_offset) { 50 }
    let(:low_watermark_offset) { 0 }
    let(:high_watermark_offset) { 100 }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(true) }
    it { expect(pagination.previous_offset?).to be(true) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_label).to eq('50') }
    it { expect(pagination.next_offset?).to be(true) }
    it { expect(pagination.previous_offset).to eq(51) }
    it { expect(pagination.next_offset).to eq(49) }
  end
end
