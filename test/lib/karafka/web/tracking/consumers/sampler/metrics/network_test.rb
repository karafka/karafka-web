# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Network do
  let(:network_metrics) { described_class.new(windows) }

  let(:windows) { stub() }
  let(:m1_window) { stub() }
  let(:stats) { stub() }

  before do
    windows.stubs(:m1).returns(m1_window)
  end

  describe "#bytes_received" do
    before do
      m1_window.stubs(:stats_from).yields("consumer_rxbytes", 1000).returns(stats)
      stats.stubs(:rps).returns(123.456)
    end

    it "calculates bytes received per second from rxbytes stats" do
      assert_equal(123, network_metrics.bytes_received)
    end

    it "rounds the result to integer" do
      stats.stubs(:rps).returns(999.999)

      assert_equal(1000, network_metrics.bytes_received)
    end
  end

  describe "#bytes_sent" do
    before do
      m1_window.stubs(:stats_from).yields("consumer_txbytes", 2000).returns(stats)
      stats.stubs(:rps).returns(456.789)
    end

    it "calculates bytes sent per second from txbytes stats" do
      assert_equal(457, network_metrics.bytes_sent)
    end

    it "rounds the result to integer" do
      stats.stubs(:rps).returns(111.111)

      assert_equal(111, network_metrics.bytes_sent)
    end
  end
end
