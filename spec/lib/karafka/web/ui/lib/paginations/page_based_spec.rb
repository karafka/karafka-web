# frozen_string_literal: true

RSpec.describe_current do
  subject(:pagination) { described_class.new(current, show_next) }

  context 'when page 1 and no more' do
    let(:current) { 1 }
    let(:show_next) { false }

    it { expect(pagination.paginate?).to be(false) }
    it { expect(pagination.first_offset?).to be(false) }
    it { expect(pagination.first_offset).to be(false) }
  end

  context 'when page 1 and more' do
    let(:current) { 1 }
    let(:show_next) { true }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(false) }
    it { expect(pagination.first_offset).to be(false) }
    it { expect(pagination.previous_offset?).to be(false) }
    it { expect(pagination.previous_offset).to eq(0) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_offset).to eq(1) }
    it { expect(pagination.next_offset?).to eq(2) }
    it { expect(pagination.offset_key).to eq('page') }
    it { expect(pagination.current_label).to eq('1') }
  end

  context 'when last page' do
    let(:current) { 10 }
    let(:show_next) { false }

    it { expect(pagination.paginate?).to be(true) }
    it { expect(pagination.first_offset?).to be(true) }
    it { expect(pagination.first_offset).to be(false) }
    it { expect(pagination.previous_offset?).to be(true) }
    it { expect(pagination.previous_offset).to eq(9) }
    it { expect(pagination.current_offset?).to be(true) }
    it { expect(pagination.current_offset).to eq(10) }
    it { expect(pagination.next_offset?).to be(false) }
    it { expect(pagination.offset_key).to eq('page') }
    it { expect(pagination.current_label).to eq('10') }
  end
end
