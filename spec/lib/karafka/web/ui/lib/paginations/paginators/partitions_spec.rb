# frozen_string_literal: true

RSpec.describe_current do
  subject(:pagination) { described_class.call(partitions_count, page) }

  context 'when there is only one partition' do
    let(:partitions_count) { 1 }
    let(:page) { 1 }

    it { expect(pagination[0]).to eq([0]) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(false) }
  end

  context 'when there are 25 partitions (matching per page)' do
    let(:partitions_count) { 25 }
    let(:page) { 1 }

    it { expect(pagination[0]).to eq((0..24).to_a) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(false) }
  end

  context 'when there are 26 partitions and first page' do
    let(:partitions_count) { 26 }
    let(:page) { 1 }

    it { expect(pagination[0]).to eq((0..12).to_a) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(true) }
  end

  context 'when there are 26 partitions and second page' do
    let(:partitions_count) { 26 }
    let(:page) { 2 }

    it { expect(pagination[0]).to eq((13..25).to_a) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(true) }
  end

  context 'when there are 26 partitions and a third page' do
    let(:partitions_count) { 26 }
    let(:page) { 3 }

    it { expect(pagination[0]).to eq((0..12).to_a) }
    it { expect(pagination[1]).to eq(2) }
    it { expect(pagination[2]).to be(true) }
  end

  context 'when there are 109 partitions and first page' do
    let(:partitions_count) { 109 }
    let(:page) { 1 }

    it { expect(pagination[0]).to eq((0..21).to_a) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(true) }
  end

  context 'when there are 109 partitions and second page' do
    let(:partitions_count) { 109 }
    let(:page) { 2 }

    it { expect(pagination[0]).to eq((22..43).to_a) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(true) }
  end

  context 'when there are 109 partitions and a third page' do
    let(:partitions_count) { 109 }
    let(:page) { 3 }

    it { expect(pagination[0]).to eq((44..65).to_a) }
    it { expect(pagination[1]).to eq(1) }
    it { expect(pagination[2]).to be(true) }
  end
end
