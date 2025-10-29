# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Network do
  subject(:network_metrics) { described_class.new(windows) }

  let(:windows) { instance_double(Karafka::Web::Tracking::Helpers::Ttls::Windows) }
  let(:m1_window) { instance_double(Karafka::Web::Tracking::Helpers::Ttls::Hash) }
  let(:stats) { instance_double(Karafka::Web::Tracking::Helpers::Ttls::Stats) }

  before do
    allow(windows).to receive(:m1).and_return(m1_window)
  end

  describe '#bytes_received' do
    before do
      allow(m1_window).to receive(:stats_from).and_yield('consumer_rxbytes', 1000).and_return(stats)
      allow(stats).to receive(:rps).and_return(123.456)
    end

    it 'calculates bytes received per second from rxbytes stats' do
      expect(network_metrics.bytes_received).to eq(123)
    end

    it 'rounds the result to integer' do
      allow(stats).to receive(:rps).and_return(999.999)
      expect(network_metrics.bytes_received).to eq(1000)
    end
  end

  describe '#bytes_sent' do
    before do
      allow(m1_window).to receive(:stats_from).and_yield('consumer_txbytes', 2000).and_return(stats)
      allow(stats).to receive(:rps).and_return(456.789)
    end

    it 'calculates bytes sent per second from txbytes stats' do
      expect(network_metrics.bytes_sent).to eq(457)
    end

    it 'rounds the result to integer' do
      allow(stats).to receive(:rps).and_return(111.111)
      expect(network_metrics.bytes_sent).to eq(111)
    end
  end
end
