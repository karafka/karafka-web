# frozen_string_literal: true

RSpec.describe_current do
  subject(:watermarks) { described_class.new(high: high, low: low) }

  let(:high) { 0 }
  let(:low) { 0 }

  describe '.find' do
    subject(:watermarks) { described_class.find(topic_id, partition_id) }

    let(:topic_id) { rand.to_s }
    let(:partition_id) { rand(10) }
    let(:high) { 100 }
    let(:low) { high - 10 }

    before do
      allow(::Karafka::Admin).to receive(:read_watermark_offsets).and_return([low, high])
    end

    it { expect(watermarks.low).to eq(low) }
    it { expect(watermarks.high).to eq(high) }
  end

  describe '#empty?' do
    context 'when both watermark offsets are zero' do
      it { expect(watermarks.empty?).to eq(true) }
    end

    context 'when when low is not zero' do
      let(:low) { 1 }

      it { expect(watermarks.empty?).to eq(false) }
    end

    context 'when high is not zero' do
      let(:high) { 1 }

      it { expect(watermarks.empty?).to eq(false) }
    end
  end

  describe '#cleaned?' do
    context 'when partition is empty' do
      it { expect(watermarks.cleaned?).to eq(false) }
    end

    context 'when there is some data' do
      let(:high) { 100 }
      let(:low) { 80 }

      it { expect(watermarks.cleaned?).to eq(false) }
    end

    context 'when there was some data but no more' do
      let(:high) { 100 }
      let(:low) { 100 }

      it { expect(watermarks.cleaned?).to eq(true) }
    end
  end
end
