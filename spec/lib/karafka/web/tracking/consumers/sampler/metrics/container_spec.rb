# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container do
  subject(:container_metrics) { described_class.new(shell) }

  let(:shell) { instance_double(Karafka::Web::Tracking::MemoizedShell) }

  describe '#memory_size' do
    context 'when cgroup memory limit is available' do
      before do
        allow(Karafka::Web::Tracking::Consumers::Sampler::Cgroup)
          .to receive(:memory_limit)
          .and_return(2 * 1024 * 1024) # 2GB in KB
      end

      it 'returns cgroup memory limit' do
        expect(container_metrics.memory_size).to eq(2 * 1024 * 1024)
      end
    end

    context 'when cgroup memory limit is not available' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
        allow(Karafka::Web::Tracking::Consumers::Sampler::Cgroup)
          .to receive(:memory_limit)
          .and_return(nil)
        allow(File).to receive(:read)
          .with('/proc/meminfo')
          .and_return("MemTotal:       16384000 kB\n")
      end

      it 'falls back to OS metrics via super' do
        expect(container_metrics.memory_size).to eq(16_384_000)
      end
    end
  end

  describe 'inheritance from Os' do
    it 'inherits all OS metrics methods' do
      expect(container_metrics).to respond_to(:memory_usage)
      expect(container_metrics).to respond_to(:memory_total_usage)
      expect(container_metrics).to respond_to(:cpu_usage)
      expect(container_metrics).to respond_to(:cpus)
      expect(container_metrics).to respond_to(:threads)
      expect(container_metrics).to respond_to(:memory_threads_ps)
    end
  end
end
