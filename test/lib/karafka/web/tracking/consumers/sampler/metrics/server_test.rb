# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Server do
  let(:server_metrics) { described_class.new }

  describe "#listeners" do
    context "when listeners are available" do
      let(:listener1) { instance_double(Karafka::Connection::Listener, active?: true) }
      let(:listener2) { instance_double(Karafka::Connection::Listener, active?: true) }
      let(:listener3) { instance_double(Karafka::Connection::Listener, active?: false) }
      let(:listeners) { [listener1, listener2, listener3] }

      before do
        allow(Karafka::Server).to receive(:listeners).and_return(listeners)
      end

      it "returns count of active and standby listeners" do
        assert_equal({active: 2, standby: 1}, server_metrics.listeners)
      end
    end

    context "when listeners are not available" do
      before do
        allow(Karafka::Server).to receive(:listeners).and_return(nil)
      end

      it "returns zero counts" do
        assert_equal({active: 0, standby: 0}, server_metrics.listeners)
      end
    end

    context "when all listeners are active" do
      let(:listener1) { instance_double(Karafka::Connection::Listener, active?: true) }
      let(:listener2) { instance_double(Karafka::Connection::Listener, active?: true) }
      let(:listeners) { [listener1, listener2] }

      before do
        allow(Karafka::Server).to receive(:listeners).and_return(listeners)
      end

      it "returns all as active, none as standby" do
        assert_equal({active: 2, standby: 0}, server_metrics.listeners)
      end
    end

    context "when all listeners are standby" do
      let(:listener1) { instance_double(Karafka::Connection::Listener, active?: false) }
      let(:listener2) { instance_double(Karafka::Connection::Listener, active?: false) }
      let(:listeners) { [listener1, listener2] }

      before do
        allow(Karafka::Server).to receive(:listeners).and_return(listeners)
      end

      it "returns none as active, all as standby" do
        assert_equal({active: 0, standby: 2}, server_metrics.listeners)
      end
    end

    context "when listeners is an empty array" do
      before do
        allow(Karafka::Server).to receive(:listeners).and_return([])
      end

      it "returns zero counts" do
        assert_equal({active: 0, standby: 0}, server_metrics.listeners)
      end
    end
  end

  describe "#workers" do
    before do
      allow(Karafka::App.config).to receive(:concurrency).and_return(10)
    end

    it "returns configured concurrency" do
      assert_equal(10, server_metrics.workers)
    end
  end
end
