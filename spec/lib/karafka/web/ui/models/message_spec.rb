# frozen_string_literal: true

RSpec.describe_current do
  let(:topic) { create_topic }
  let(:partition) { 0 }
  let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.find(topic, partition) }

  describe '#find' do
    let(:message) { described_class.find(topic, partition, offset) }

    context 'when topic does not exist' do
      let(:topic) { SecureRandom.uuid }
      let(:partition) { 0 }
      let(:offset) { 1 }

      it { expect { message }.to raise_error(::Rdkafka::RdkafkaError) }
    end

    context 'when partition does not exist' do
      let(:partition) { 1 }
      let(:offset) { 1 }

      it { expect { message }.to raise_error(::Rdkafka::RdkafkaError) }
    end

    context 'when offset does not exist' do
      let(:partition) { 0 }
      let(:offset) { 1 }

      it { expect { message }.to raise_error(::Karafka::Web::Errors::Ui::NotFoundError) }
    end

    context 'when message exists' do
      let(:partition) { 0 }
      let(:offset) { 1 }

      before { 2.times { |i| produce(topic, i.to_s) } }

      it do
        expect(message.raw_payload).to eq('1')
        expect(message.offset).to eq(1)
      end
    end
  end

  describe '#offset_page' do
    subject(:page) do
      described_class.offset_page(topic, partition, start_offset, watermark_offsets)
    end

    context 'when topic does not exist' do
      let(:topic) { SecureRandom.uuid }
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 0) }

      it { expect(page).to eq([false, [], false]) }
    end

    context 'when partition does not exist' do
      let(:partition) { 1 }
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 0) }

      it { expect(page).to eq([false, [], false]) }
    end

    context 'when partition is empty' do
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 0) }

      it { expect(page).to eq([false, [], false]) }
    end

    context 'when partition is fully compacted and we start from beginning' do
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it 'expect to fill all the compacted with messages dummies' do
        dummies = (0..24).map { |i| [0, i] }.reverse
        expect(page).to eq([25, dummies, false])
      end
    end

    context 'when partition is fully compacted and we try to go beyond what existed' do
      let(:start_offset) { 100 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it 'expect to return nothing' do
        expect(page).to eq([false, [], false])
      end
    end

    context 'when partition is fully compacted and we start from last' do
      let(:start_offset) { 99 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it 'expect to fill all the compacted with messages dummies' do
        expect(page).to eq([false, [[0, 99]], 74])
      end
    end

    context 'when partition is fully compacted and we start from the middle' do
      let(:start_offset) { 50 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it 'expect to fill all the compacted with messages dummies' do
        dummies = (50..74).map { |i| [0, i] }.reverse
        expect(page).to eq([75, dummies, 25])
      end
    end

    context 'when there are few regular messages and we fetch beyond that' do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 50 }

      it 'expect to return nothing' do
        expect(page).to eq([false, [], false])
      end
    end

    context 'when there are few regular messages and we fetch from beginning' do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 0 }

      it 'expect to return them in order' do
        expect(page[0]).to eq(false)
        expect(page[1].map(&:offset)).to eq((0..6).to_a.reverse)
        expect(page[2]).to eq(false)
      end
    end

    context 'when there are few regular messages and we fetch near the beginning' do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 2 }

      it 'expect to return them in order' do
        expect(page[0]).to eq(false)
        expect(page[1].map(&:offset)).to eq((2..6).to_a.reverse)
        expect(page[2]).to eq(0)
      end
    end

    context 'when there are few regular messages and we fetch from the last' do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 6 }

      it 'expect to return them in order' do
        expect(page[0]).to eq(false)
        expect(page[1].map(&:offset)).to eq([6])
        expect(page[2]).to eq(0)
      end
    end

    context 'when there are messages beyond a single page and we start from beginning' do
      before { produce_many(topic, (0..100).map(&:to_s)) }

      let(:start_offset) { 0 }

      it 'expect to return them in order' do
        expect(page[0]).to eq(25)
        expect(page[1].map(&:offset)).to eq((0..24).to_a.reverse)
        expect(page[2]).to eq(false)
      end
    end

    context 'when there are messages beyond a single page and we start from the last one' do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { 99 }

      it 'expect to return them in order' do
        expect(page[0]).to eq(false)
        expect(page[1].map(&:offset)).to eq([99])
        expect(page[2]).to eq(74)
      end
    end

    context 'when there are messages beyond a single page and we start from the middle' do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { 50 }

      it 'expect to return them in order' do
        expect(page[0]).to eq(75)
        expect(page[1].map(&:offset)).to eq((50..74).to_a.reverse)
        expect(page[2]).to eq(25)
      end
    end
  end

  describe '#topic_page' do

  end
end
