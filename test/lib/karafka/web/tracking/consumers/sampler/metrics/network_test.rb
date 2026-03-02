# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Network do
  let(:network_metrics) { described_class.new(windows) }

  let(:windows) { instance_double(Karafka::Web::Tracking::Helpers::Ttls::Windows) }
  let(:m1_window) { instance_double(Karafka::Web::Tracking::Helpers::Ttls::Hash) }
  let(:stats) { instance_double(Karafka::Web::Tracking::Helpers::Ttls::Stats) }

  before do
    allow(windows).to receive(:m1).and_return(m1_window)
  end

  describe "#bytes_received" do
    before do
      allow(m1_window).to receive(:stats_from).and_yield("consumer_rxbytes", 1000).and_return(stats)
      allow(stats).to receive(:rps).and_return(123.456)
    end

    it "calculates bytes received per second from rxbytes stats" do
      assert_equal(123, network_metrics.bytes_received)
    end

    it "rounds the result to integer" do
      allow(stats).to receive(:rps).and_return(999.999)
      assert_equal(1000, network_metrics.bytes_received)
    end
  end

  describe "#bytes_sent" do
    before do
      allow(m1_window).to receive(:stats_from).and_yield("consumer_txbytes", 2000).and_return(stats)
      allow(stats).to receive(:rps).and_return(456.789)
    end

    it "calculates bytes sent per second from txbytes stats" do
      assert_equal(457, network_metrics.bytes_sent)
    end

    it "rounds the result to integer" do
      allow(stats).to receive(:rps).and_return(111.111)
      assert_equal(111, network_metrics.bytes_sent)
    end
  end
end
