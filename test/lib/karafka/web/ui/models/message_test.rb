# frozen_string_literal: true

require "karafka/pro/iterator"
require "karafka/pro/iterator/expander"
require "karafka/pro/iterator/tpl_builder"

describe_current do
  let(:topic) { create_topic }
  let(:partition) { 0 }
  let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.find(topic, partition) }

  describe "#find" do
    let(:message) { described_class.find(topic, partition, offset) }

    context "when topic does not exist" do
      let(:topic) { generate_topic_name }
      let(:partition) { 0 }
      let(:offset) { 1 }

      it { assert_raises(Rdkafka::RdkafkaError) { message } }
    end

    context "when partition does not exist" do
      let(:partition) { 1 }
      let(:offset) { 1 }

      it { assert_raises(Rdkafka::RdkafkaError) { message } }
    end

    context "when offset does not exist" do
      let(:partition) { 0 }
      let(:offset) { 1 }

      it { assert_raises(Karafka::Web::Errors::Ui::NotFoundError) { message } }
    end

    context "when message exists" do
      let(:partition) { 0 }
      let(:offset) { 1 }

      before { 2.times { |i| produce(topic, i.to_s) } }

      it do
        assert_equal("1", message.raw_payload)
        assert_equal(1, message.offset)
      end
    end
  end

  describe "#offset_page" do
    let(:page) do
      described_class.offset_page(topic, partition, start_offset, watermark_offsets)
    end

    context "when topic does not exist" do
      let(:topic) { generate_topic_name }
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 0) }

      it { assert_equal([false, [], false], page) }
    end

    context "when partition does not exist" do
      let(:partition) { 1 }
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 0) }

      it { assert_equal([false, [], false], page) }
    end

    context "when partition is empty" do
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 0) }

      it { assert_equal([false, [], false], page) }
    end

    context "when partition is fully compacted and we start from beginning" do
      let(:start_offset) { 0 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it "expect to fill all the compacted with messages dummies" do
        dummies = (0..24).map { |i| [0, i] }.reverse

        assert_equal([25, dummies, false], page)
      end
    end

    context "when partition is fully compacted and we try to go beyond what existed" do
      let(:start_offset) { 100 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it "expect to return nothing" do
        assert_equal([false, [], false], page)
      end
    end

    context "when partition is fully compacted and we start from last" do
      let(:start_offset) { 99 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it "expect to fill all the compacted with messages dummies" do
        assert_equal([false, [[0, 99]], 74], page)
      end
    end

    context "when partition is fully compacted and we start from the middle" do
      let(:start_offset) { 50 }
      let(:watermark_offsets) { Karafka::Web::Ui::Models::WatermarkOffsets.new(low: 0, high: 100) }

      it "expect to fill all the compacted with messages dummies" do
        dummies = (50..74).map { |i| [0, i] }.reverse

        assert_equal([75, dummies, 25], page)
      end
    end

    context "when there are few regular messages and we fetch beyond that" do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 50 }

      it "expect to return nothing" do
        assert_equal([false, [], false], page)
      end
    end

    context "when there are few regular messages and we fetch from beginning" do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 0 }

      it "expect to return them in order" do
        refute(page[0])
        assert_equal((0..6).to_a.reverse, page[1].map(&:offset))
        refute(page[2])
      end
    end

    context "when there are few regular messages and we fetch near the beginning" do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 2 }

      it "expect to return them in order" do
        refute(page[0])
        assert_equal((2..6).to_a.reverse, page[1].map(&:offset))
        assert_equal(0, page[2])
      end
    end

    context "when there are few regular messages and we fetch from the last" do
      before { produce_many(topic, (0..6).map(&:to_s)) }

      let(:start_offset) { 6 }

      it "expect to return them in order" do
        refute(page[0])
        assert_equal([6], page[1].map(&:offset))
        assert_equal(0, page[2])
      end
    end

    context "when there are messages beyond a single page and we start from beginning" do
      before { produce_many(topic, (0..100).map(&:to_s)) }

      let(:start_offset) { 0 }

      it "expect to return them in order" do
        assert_equal(25, page[0])
        assert_equal((0..24).to_a.reverse, page[1].map(&:offset))
        refute(page[2])
      end
    end

    context "when there are messages beyond a single page and we start from the last one" do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { 99 }

      it "expect to return them in order" do
        refute(page[0])
        assert_equal([99], page[1].map(&:offset))
        assert_equal(74, page[2])
      end
    end

    context "when there are messages beyond a single page and we start from the middle" do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { 50 }

      it "expect to return them in order" do
        assert_equal(75, page[0])
        assert_equal((50..74).to_a.reverse, page[1].map(&:offset))
        assert_equal(25, page[2])
      end
    end

    context "when there is a lot of data and we want the most recent page (-1)" do
      before { produce_many(topic, (0..99).map(&:to_s)) }

      let(:start_offset) { -1 }

      it "expect to return it in order" do
        refute(page[0])
        assert_equal((75..99).to_a.reverse, page[1].map(&:offset))
        assert_equal(50, page[2])
      end
    end
  end

  describe "#topic_page" do
    let(:result) { described_class.topic_page(topic, partitions_ids, page) }

    let(:topic) { create_topic(partitions: 4) }
    let(:partitions_ids) { (0..3).to_a }
    let(:page) { 1 }

    context "when there is no data in any of the partitions" do
      it { assert_equal([[], false], result) }
    end

    context "when we try to reach beyond first page on empty" do
      let(:page) { 2 }

      it { assert_equal([[], false], result) }
    end

    context "when there is some data in the first partition only" do
      before { produce_many(topic, (0..3).map(&:to_s), partition: 0) }

      it "expect to return this data" do
        assert_equal([3, 2, 1, 0], result[0].map(&:offset))
        refute(result[1])
      end
    end

    context "when there is some data in each of the partitions" do
      before do
        produce(topic, "0", partition: 0)
        produce(topic, "1", partition: 1)
        produce(topic, "2", partition: 2)
        produce(topic, "3", partition: 3)
      end

      it "expect to return this data" do
        assert_equal([0, 0, 0, 0], result[0].map(&:offset))
        assert_equal([0, 1, 2, 3], result[0].map(&:partition))
        refute(result[1])
      end
    end

    context "when there are more partitions than space on the first page but data only beyond" do
      let(:topic) { create_topic(partitions: 100) }
      let(:partitions_ids) { (25..29).to_a }

      before do
        produce(topic, "0", partition: 24)
        produce(topic, "0", partition: 25)
        produce(topic, "1", partition: 26)
        produce(topic, "2", partition: 27)
        produce(topic, "3", partition: 28)
      end

      it "expect to fetch from partitions we want" do
        assert_equal([0, 0, 0, 0], result[0].map(&:offset))
        assert_equal((25..28).to_a, result[0].map(&:partition))
        refute(result[1])
      end
    end
  end
end
