# frozen_string_literal: true

describe_current do
  let(:producer) { described_class.new }

  let(:default_producer) { stub() }
  let(:variant) { stub() }

  before do
    Karafka.stubs(:producer).returns(default_producer)
  end

  describe "#__getobj__" do
    context "when default producer is not idempotent and not transactional" do
      before do
        default_producer.stubs(:idempotent?).returns(false)
        default_producer.stubs(:transactional?).returns(false)
        default_producer.stubs(:variant).with(topic_config: { acks: 0 }).returns(variant)
      end

      it "returns a variant with acks: 0" do
        assert_equal(variant, producer.__getobj__)
      end

      it "creates the variant with correct topic_config" do
        default_producer.expects(:variant).with(topic_config: { acks: 0 }).returns(variant)
        producer.__getobj__
      end

      it "caches the result on subsequent calls" do
        default_producer.expects(:variant).once.returns(variant)
        3.times { producer.__getobj__ }
      end
    end

    context "when default producer is idempotent" do
      before do
        default_producer.stubs(:idempotent?).returns(true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.__getobj__)
      end

      it "does not create a variant" do
        default_producer.expects(:variant).never
        producer.__getobj__
      end

      it "caches the result on subsequent calls" do
        default_producer.expects(:idempotent?).once.returns(true)
        3.times { producer.__getobj__ }
      end
    end

    context "when default producer is transactional" do
      before do
        default_producer.stubs(:idempotent?).returns(false)
        default_producer.stubs(:transactional?).returns(true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.__getobj__)
      end

      it "does not create a variant" do
        default_producer.expects(:variant).never
        producer.__getobj__
      end

      it "caches the result on subsequent calls" do
        default_producer.expects(:transactional?).once.returns(true)
        3.times { producer.__getobj__ }
      end
    end

    context "when default producer is both idempotent and transactional" do
      before do
        default_producer.stubs(:idempotent?).returns(true)
        default_producer.stubs(:transactional?).returns(true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.__getobj__)
      end

      it "checks idempotent first and short-circuits" do
        default_producer.expects(:idempotent?).returns(true)
        default_producer.expects(:transactional?).never
        producer.__getobj__
      end
    end
  end

  describe "delegation" do
    before do
      default_producer.stubs(:idempotent?).returns(false)
      default_producer.stubs(:transactional?).returns(false)
      default_producer.stubs(:variant).with(topic_config: { acks: 0 }).returns(variant)
    end

    it "delegates method calls to the underlying producer" do
      variant.expects(:produce_async).with(topic: "test", payload: "data").returns(true)
      result = producer.produce_async(topic: "test", payload: "data")

      assert(result)
    end

    it "responds to producer methods" do
      variant.stubs(:respond_to?).with(:produce_async, false).returns(true)

      assert_respond_to(producer, :produce_async)
    end
  end

  describe "integration with real producers", :slow do
    context "with the regular PRODUCERS.regular" do
      let(:producer) { described_class.new }

      before do
        Karafka.stubs(:producer).returns(PRODUCERS.regular)
      end

      it "returns a variant since regular producer is not idempotent" do
        result = producer.__getobj__

        # Regular producer should not be idempotent, so we get a variant
        if PRODUCERS.regular.idempotent?
          assert_equal(PRODUCERS.regular, result)
        else
          assert_kind_of(WaterDrop::Producer::Variant, result)
        end
      end
    end

    context "with the transactional PRODUCERS.transactional" do
      let(:producer) { described_class.new }

      before do
        Karafka.stubs(:producer).returns(PRODUCERS.transactional)
      end

      it "returns the original producer since transactional producer requires acks: all" do
        result = producer.__getobj__

        # Transactional producer cannot have acks changed, so original is returned
        assert_equal(PRODUCERS.transactional, result)
      end
    end
  end
end
