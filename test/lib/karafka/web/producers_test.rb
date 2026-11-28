# frozen_string_literal: true

describe_current do
  describe ".default" do
    it "returns the configured Web UI producer" do
      producer = Object.new
      Karafka::Web.stubs(:producer).returns(producer)

      assert_equal(producer, described_class.default)
    end
  end

  describe ".acked" do
    context "when the default producer exposes an acked variant" do
      let(:acked) { Object.new }
      let(:default_producer) { stub }

      before do
        default_producer.stubs(:respond_to?).with(:acked).returns(true)
        default_producer.stubs(:acked).returns(acked)
        Karafka::Web.stubs(:producer).returns(default_producer)
      end

      it "returns the acked variant" do
        assert_equal(acked, described_class.acked)
      end
    end

    context "when the default producer has no acked variant" do
      let(:default_producer) { stub }

      before do
        default_producer.stubs(:respond_to?).with(:acked).returns(false)
        Karafka::Web.stubs(:producer).returns(default_producer)
      end

      it "falls back to the default producer" do
        assert_equal(default_producer, described_class.acked)
      end
    end
  end

  describe ".fully_acked" do
    let(:kafka) { Karafka::Setup::AttributesMap.producer(Karafka::App.config.kafka.dup) }

    context "when the default producer exposes a fully acked variant" do
      let(:fully_acked) { Object.new }
      let(:default_producer) { stub }

      before do
        default_producer.stubs(:respond_to?).with(:fully_acked).returns(true)
        default_producer.stubs(:fully_acked).returns(fully_acked)
        Karafka::Web.stubs(:producer).returns(default_producer)
      end

      it { assert_equal(fully_acked, described_class.fully_acked) }
    end

    context "when a custom producer uses acks 0" do
      let(:custom) do
        config = kafka.merge("request.required.acks": 0)

        WaterDrop::Producer.new { |p_config| p_config.kafka = config }
      end

      before { Karafka::Web.stubs(:producer).returns(custom) }

      after { custom.close }

      it "builds an acks: all variant of it once" do
        variant = described_class.fully_acked

        assert_kind_of(WaterDrop::Producer::Variant, variant)
        assert_same(custom, variant.producer)
        assert_equal("all", variant.topic_config[:acks])
        assert_same(variant, described_class.fully_acked)
      end
    end

    context "when a custom producer is a variant" do
      let(:custom) { WaterDrop::Producer.new { |p_config| p_config.kafka = kafka } }
      let(:custom_variant) { custom.variant(topic_config: { acks: 0, "compression.codec": "gzip" }) }

      before { Karafka::Web.stubs(:producer).returns(custom_variant) }

      after { custom.close }

      it "keeps its topic config with acks: all" do
        variant = described_class.fully_acked

        assert_same(custom, variant.producer)
        assert_equal({ acks: "all", "compression.codec": "gzip" }, variant.topic_config)
      end
    end

    context "when a custom producer is idempotent" do
      let(:custom) do
        config = kafka.merge("enable.idempotence": true)

        WaterDrop::Producer.new { |p_config| p_config.kafka = config }
      end

      before { Karafka::Web.stubs(:producer).returns(custom) }

      after { custom.close }

      it { assert_same(custom, described_class.fully_acked) }
    end
  end
end
