# frozen_string_literal: true

describe_current do
  let(:watermarks) { described_class.new(high: high, low: low) }

  let(:high) { 0 }
  let(:low) { 0 }

  describe ".find" do
    let(:watermarks) { described_class.find(topic_id, partition_id) }

    let(:topic_id) { rand.to_s }
    let(:partition_id) { rand(10) }
    let(:high) { 100 }
    let(:low) { high - 10 }

    before do
      allow(Karafka::Admin).to receive(:read_watermark_offsets).and_return([low, high])
    end

    it { assert_equal(low, watermarks.low) }
    it { assert_equal(high, watermarks.high) }
  end

  describe "#empty?" do
    context "when both watermark offsets are zero" do
      it { assert_empty(watermarks) }
    end

    context "when when low is not zero" do
      let(:low) { 1 }

      it { refute_empty(watermarks) }
    end

    context "when high is not zero" do
      let(:high) { 1 }

      it { refute_empty(watermarks) }
    end
  end

  describe "#cleaned?" do
    context "when partition is empty" do
      it { refute(watermarks.cleaned?) }
    end

    context "when there is some data" do
      let(:high) { 100 }
      let(:low) { 80 }

      it { refute(watermarks.cleaned?) }
    end

    context "when there was some data but no more" do
      let(:high) { 100 }
      let(:low) { 100 }

      it { assert(watermarks.cleaned?) }
    end
  end

  context "when Kafka topic does not exist" do
    it do
      assert_raises(Rdkafka::RdkafkaError) { described_class.find(SecureRandom.uuid, 0) }
    end
  end

  context "when Kafka partition does not exist" do
    let(:topic) { create_topic }

    it { assert_raises(Rdkafka::RdkafkaError) { described_class.find(topic, 2) } }
  end

  context "when topic and partition and there is no data" do
    let(:topic) { create_topic }

    it "expect to return correct values" do
      result = described_class.find(topic, 0)

      assert_equal(0, result.low)
      assert_equal(0, result.high)
      assert_empty(result)
      refute(result.cleaned?)
    end
  end

  context "when topic and partition and there is some no data" do
    let(:topic) { create_topic }

    before { 2.times { produce(topic) } }

    it "expect to return correct values" do
      result = described_class.find(topic, 0)

      assert_equal(0, result.low)
      assert_equal(2, result.high)
      refute_empty(result)
      refute(result.cleaned?)
    end
  end
end
