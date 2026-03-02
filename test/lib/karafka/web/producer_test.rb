# frozen_string_literal: true

describe_current do
  let(:producer) { described_class.new }

  let(:default_producer) { instance_double(WaterDrop::Producer) }
  let(:variant) { instance_double(WaterDrop::Producer::Variant) }

  before do
    allow(Karafka).to receive(:producer).and_return(default_producer)
  end

  describe "#__getobj__" do
    context "when default producer is not idempotent and not transactional" do
      before do
        allow(default_producer).to receive_messages(idempotent?: false, transactional?: false)
        allow(default_producer).to receive(:variant)
          .with(topic_config: { acks: 0 })
          .and_return(variant)
      end

      it "returns a variant with acks: 0" do
        assert_equal(variant, producer.__getobj__)
      end

      it "creates the variant with correct topic_config" do
        producer.__getobj__
        expect(default_producer).to have_received(:variant).with(topic_config: { acks: 0 })
      end

      it "caches the result on subsequent calls" do
        3.times { producer.__getobj__ }
        expect(default_producer).to have_received(:variant).once
      end
    end

    context "when default producer is idempotent" do
      before do
        allow(default_producer).to receive(:idempotent?).and_return(true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.__getobj__)
      end

      it "does not create a variant" do
        allow(default_producer).to receive(:variant)
        producer.__getobj__
        expect(default_producer).not_to have_received(:variant)
      end

      it "caches the result on subsequent calls" do
        3.times { producer.__getobj__ }
        expect(default_producer).to have_received(:idempotent?).once
      end
    end

    context "when default producer is transactional" do
      before do
        allow(default_producer).to receive_messages(idempotent?: false, transactional?: true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.__getobj__)
      end

      it "does not create a variant" do
        allow(default_producer).to receive(:variant)
        producer.__getobj__
        expect(default_producer).not_to have_received(:variant)
      end

      it "caches the result on subsequent calls" do
        3.times { producer.__getobj__ }
        expect(default_producer).to have_received(:transactional?).once
      end
    end

    context "when default producer is both idempotent and transactional" do
      before do
        allow(default_producer).to receive_messages(idempotent?: true, transactional?: true)
      end

      it "returns the default producer unchanged" do
        assert_equal(default_producer, producer.__getobj__)
      end

      it "checks idempotent first and short-circuits" do
        producer.__getobj__
        expect(default_producer).to have_received(:idempotent?)
        expect(default_producer).not_to have_received(:transactional?)
      end
    end
  end

  describe "delegation" do
    before do
      allow(default_producer).to receive_messages(idempotent?: false, transactional?: false)
      allow(default_producer).to receive(:variant)
        .with(topic_config: { acks: 0 })
        .and_return(variant)
    end

    it "delegates method calls to the underlying producer" do
      allow(variant).to receive(:produce_async).and_return(true)

      result = producer.produce_async(topic: "test", payload: "data")

      expect(variant).to have_received(:produce_async).with(topic: "test", payload: "data")
      assert_equal(true, result)
    end

    it "responds to producer methods" do
      allow(variant).to receive(:respond_to?).with(:produce_async, false).and_return(true)

      assert_equal(true, producer.respond_to?(:produce_async))
    end
  end

  describe "integration with real producers", :slow do
    context "with the regular PRODUCERS.regular" do
      let(:producer) { described_class.new }

      before do
        allow(Karafka).to receive(:producer).and_return(PRODUCERS.regular)
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
        allow(Karafka).to receive(:producer).and_return(PRODUCERS.transactional)
      end

      it "returns the original producer since transactional producer requires acks: all" do
        result = producer.__getobj__

        # Transactional producer cannot have acks changed, so original is returned
        assert_equal(PRODUCERS.transactional, result)
      end
    end
  end
end
