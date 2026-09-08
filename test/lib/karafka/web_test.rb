# frozen_string_literal: true

describe_current do
  describe ".acked_producer" do
    context "when the configured producer exposes an acked variant" do
      let(:acked) { Object.new }
      let(:web_producer) { stub }

      before do
        web_producer.stubs(:respond_to?).with(:acked).returns(true)
        web_producer.stubs(:acked).returns(acked)
        Karafka::Web.stubs(:producer).returns(web_producer)
      end

      it "returns the acked variant" do
        assert_equal(acked, Karafka::Web.acked_producer)
      end
    end

    context "when the configured producer has no acked variant" do
      let(:web_producer) { stub }

      before do
        web_producer.stubs(:respond_to?).with(:acked).returns(false)
        Karafka::Web.stubs(:producer).returns(web_producer)
      end

      it "falls back to the configured producer" do
        assert_equal(web_producer, Karafka::Web.acked_producer)
      end
    end
  end
end
