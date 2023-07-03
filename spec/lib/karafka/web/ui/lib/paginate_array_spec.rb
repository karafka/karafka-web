# frozen_string_literal: true

RSpec.describe_current do
  subject(:pagination) { described_class.call(array, page) }

  context 'when a bit of data and page 1' do
    let(:array) { [1, 2, 3] }
    let(:page) { 1 }

    it { expect(pagination[0]).to eq([1, 2, 3]) }
    it { expect(pagination[1]).to eq(true) }
  end

  context 'when a lot of data and page 1' do
    let(:array) { (0..100).to_a }
    let(:page) { 1 }

    it { expect(pagination[0]).to eq((0..24).to_a) }
    it { expect(pagination[1]).to eq(false) }
  end

  context 'when a lot of data and last page' do
    let(:array) { (0..110).to_a }
    let(:page) { 5 }

    it { expect(pagination[0]).to eq((100..110).to_a) }
    it { expect(pagination[1]).to eq(true) }
  end

  context 'when no data and page 1' do
    let(:array) { [] }
    let(:page) { 2 }

    it { expect(pagination[0]).to eq([]) }
    it { expect(pagination[1]).to eq(true) }
  end

  context 'when no data and page 2' do
    let(:array) { [] }
    let(:page) { 2 }

    it { expect(pagination[0]).to eq([]) }
    it { expect(pagination[1]).to eq(true) }
  end
end
