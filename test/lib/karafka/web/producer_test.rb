# frozen_string_literal: true

describe_current do
  let(:producer) { described_class.new }

  let(:default_producer) { stub }
  let(:variant) { stub }

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

    # `SimpleDelegator#method_missing` always passes a block to `__getobj__`.
    # `SimpleDelegator#__getobj__` implicitly accepts the block via `block_given?` and
    # `yield`, but our block-ignoring subclass must explicitly accept a block to avoid
    # Ruby 3.4's `strict_unused_block` warning on every delegated call.
    it "accepts a block to preserve the SimpleDelegator __getobj__ contract" do
      params = described_class.instance_method(:__getobj__).parameters

      assert(
        params.any? { |type, _| type == :block },
        "Expected __getobj__ to declare a block parameter to avoid " \
          "`strict_unused_block` warnings from SimpleDelegator#method_missing, " \
          "got parameters: #{params.inspect}"
      )
    end
  end

  # This wrapper is a lazy singleton on `Web.config.producer`, so it outlives a fork. Without a
  # pid check a child would keep serving variants built from the parent's `::Karafka.producer`.
  describe "fork awareness" do
    before do
      default_producer.stubs(:idempotent?).returns(false)
      default_producer.stubs(:transactional?).returns(false)
      default_producer.stubs(:variant).returns(variant)
    end

    context "when the process did not change" do
      it "expect to build the acks: 0 variant once" do
        default_producer.expects(:variant).once.returns(variant)
        3.times { producer.__getobj__ }
      end

      it "expect to build the acks: 1 variant once" do
        default_producer.expects(:variant).once.returns(variant)
        3.times { producer.acked }
      end
    end

    context "when the process changed" do
      it "expect to rebuild the acks: 0 variant" do
        default_producer.expects(:variant).twice.returns(variant)

        producer.__getobj__
        # Read the real pid first: evaluating `Process.pid` as the stub's return value would hit
        # the stub itself and yield nil.
        forked_pid = Process.pid + 1
        Process.stubs(:pid).returns(forked_pid)
        producer.__getobj__
      end

      it "expect to rebuild the acks: 1 variant" do
        default_producer.expects(:variant).twice.returns(variant)

        producer.acked
        # Read the real pid first: evaluating `Process.pid` as the stub's return value would hit
        # the stub itself and yield nil.
        forked_pid = Process.pid + 1
        Process.stubs(:pid).returns(forked_pid)
        producer.acked
      end

      # `__getobj__` guards on `@initialized`, which is a separate ivar from the delegate, so a
      # partial reset would hand back a nil delegate instead of a rebuilt variant.
      it "expect to return the rebuilt variant rather than nil" do
        producer.__getobj__
        # Read the real pid first: evaluating `Process.pid` as the stub's return value would hit
        # the stub itself and yield nil.
        forked_pid = Process.pid + 1
        Process.stubs(:pid).returns(forked_pid)

        assert_equal(variant, producer.__getobj__)
      end
    end
  end

  describe "#acked" do
    context "when default producer is not idempotent and not transactional" do
      before do
        default_producer.stubs(:idempotent?).returns(false)
        default_producer.stubs(:transactional?).returns(false)
        default_producer.stubs(:variant).with(topic_config: { acks: 1 }).returns(variant)
      end

      it "returns a variant with acks: 1" do
        assert_equal(variant, producer.acked)
      end

      it "caches the result on subsequent calls" do
        default_producer.expects(:variant).once.returns(variant)
        3.times { producer.acked }
      end
    end

    context "when default producer is idempotent" do
      before { default_producer.stubs(:idempotent?).returns(true) }

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.acked)
      end

      it "does not create a variant" do
        default_producer.expects(:variant).never
        producer.acked
      end
    end

    context "when default producer is transactional" do
      before do
        default_producer.stubs(:idempotent?).returns(false)
        default_producer.stubs(:transactional?).returns(true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.acked)
      end

      it "does not create a variant" do
        default_producer.expects(:variant).never
        producer.acked
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
