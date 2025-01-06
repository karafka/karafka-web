# frozen_string_literal: true

require 'karafka/pro/iterator'
require 'karafka/pro/iterator/expander'
require 'karafka/pro/iterator/tpl_builder'

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
        expect(page[0]).to be(false)
        expect(page[1].map(&:offset)).to eq((0..6).to_a.reverse)
        expect(page[2]).to be(false)
      end
    end

    context 'when there are few regular messages and we fetch near the beginning' do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 2 }

      it 'expect to return them in order' do
        expect(page[0]).to be(false)
        expect(page[1].map(&:offset)).to eq((2..6).to_a.reverse)
        expect(page[2]).to eq(0)
      end
    end

    context 'when there are few regular messages and we fetch from the last' do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 6 }

      it 'expect to return them in order' do
        expect(page[0]).to be(false)
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
        expect(page[2]).to be(false)
      end
    end

    context 'when there are messages beyond a single page and we start from the last one' do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { 99 }

      it 'expect to return them in order' do
        expect(page[0]).to be(false)
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

    context 'when there is a lot of data and we want the most recent page (-1)' do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { -1 }

      it 'expect to return it in order' do
        expect(page[0]).to be(false)
        expect(page[1].map(&:offset)).to eq((75..99).to_a.reverse)
        expect(page[2]).to eq(50)
      end
    end
  end

  describe '#topic_page' do
    subject(:result) { described_class.topic_page(topic, partitions_ids, page) }

    let(:topic) { create_topic(partitions: 4) }
    let(:partitions_ids) { (0..3).to_a }
    let(:page) { 1 }

    context 'when there is no data in any of the partitions' do
      it { expect(result).to eq([[], false]) }
    end

    context 'when we try to reach beyond first page on empty' do
      let(:page) { 2 }

      it { expect(result).to eq([[], false]) }
    end

    context 'when there is some data in the first partition only' do
      before { produce_many(topic, (0..3).map(&:to_s), partition: 0) }

      it 'expect to return this data' do
        expect(result[0].map(&:offset)).to eq([3, 2, 1, 0])
        expect(result[1]).to be(false)
      end
    end

    context 'when there is some data in each of the partitions' do
      before do
        produce(topic, '0', partition: 0)
        produce(topic, '1', partition: 1)
        produce(topic, '2', partition: 2)
        produce(topic, '3', partition: 3)
      end

      it 'expect to return this data' do
        expect(result[0].map(&:offset)).to eq([0, 0, 0, 0])
        expect(result[0].map(&:partition)).to eq([0, 1, 2, 3])
        expect(result[1]).to be(false)
      end
    end

    context 'when there are more partitions than space on the first page but data only beyond' do
      let(:topic) { create_topic(partitions: 100) }
      let(:partitions_ids) { (25..29).to_a }

      before do
        produce(topic, '0', partition: 24)
        produce(topic, '0', partition: 25)
        produce(topic, '1', partition: 26)
        produce(topic, '2', partition: 27)
        produce(topic, '3', partition: 28)
      end

      it 'expect to fetch from partitions we want' do
        expect(result[0].map(&:offset)).to eq([0, 0, 0, 0])
        expect(result[0].map(&:partition)).to eq((25..28).to_a)
        expect(result[1]).to be(false)
      end
    end
  end
end
