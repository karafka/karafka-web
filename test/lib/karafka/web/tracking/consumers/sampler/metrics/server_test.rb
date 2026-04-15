# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Server do
  let(:server_metrics) { described_class.new }

  describe "#listeners" do
    context "when listeners are available" do
      let(:listener1) { stub(active?: true) }
      let(:listener2) { stub(active?: true) }
      let(:listener3) { stub(active?: false) }
      let(:listeners) { [listener1, listener2, listener3] }

      before do
        Karafka::Server.stubs(:listeners).returns(listeners)
      end

      it "returns count of active and standby listeners" do
        assert_equal({ active: 2, standby: 1 }, server_metrics.listeners)
      end
    end

    context "when listeners are not available" do
      before do
        Karafka::Server.stubs(:listeners).returns(nil)
      end

      it "returns zero counts" do
        assert_equal({ active: 0, standby: 0 }, server_metrics.listeners)
      end
    end

    context "when all listeners are active" do
      let(:listener1) { stub(active?: true) }
      let(:listener2) { stub(active?: true) }
      let(:listeners) { [listener1, listener2] }

      before do
        Karafka::Server.stubs(:listeners).returns(listeners)
      end

      it "returns all as active, none as standby" do
        assert_equal({ active: 2, standby: 0 }, server_metrics.listeners)
      end
    end

    context "when all listeners are standby" do
      let(:listener1) { stub(active?: false) }
      let(:listener2) { stub(active?: false) }
      let(:listeners) { [listener1, listener2] }

      before do
        Karafka::Server.stubs(:listeners).returns(listeners)
      end

      it "returns none as active, all as standby" do
        assert_equal({ active: 0, standby: 2 }, server_metrics.listeners)
      end
    end

    context "when listeners is an empty array" do
      before do
        Karafka::Server.stubs(:listeners).returns([])
      end

      it "returns zero counts" do
        assert_equal({ active: 0, standby: 0 }, server_metrics.listeners)
      end
    end
  end

  describe "#workers" do
    before do
      Karafka::Server.workers.stubs(:size).returns(10)
    end

    it "returns configured concurrency" do
      assert_equal(10, server_metrics.workers)
    end
  end
end
