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
end
