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

      it 'falls back to OS metrics' do
        expect(container_metrics.memory_size).to eq(16_384_000)
      end
    end
  end

  describe 'delegation to os_metrics' do
    let(:memory_threads_ps) { [[1024, 10, Process.pid]] }
    let(:os_metrics) { instance_double(Karafka::Web::Tracking::Consumers::Sampler::Metrics::Os) }

    before do
      allow(Karafka::Web::Tracking::Consumers::Sampler::Metrics::Os)
        .to receive(:new)
        .with(shell)
        .and_return(os_metrics)
    end

    describe '#memory_usage' do
      it 'delegates to os_metrics' do
        allow(os_metrics).to receive(:memory_usage).and_return(12_345)
        expect(container_metrics.memory_usage).to eq(12_345)
        expect(os_metrics).to have_received(:memory_usage)
      end
    end

    describe '#memory_total_usage' do
      it 'delegates to os_metrics' do
        allow(os_metrics).to receive(:memory_total_usage).and_return(1024)
        expect(container_metrics.memory_total_usage(memory_threads_ps)).to eq(1024)
        expect(os_metrics).to have_received(:memory_total_usage).with(memory_threads_ps)
      end
    end

    describe '#cpu_usage' do
      it 'delegates to os_metrics' do
        allow(os_metrics).to receive(:cpu_usage).and_return([1.0, 2.0, 3.0])
        expect(container_metrics.cpu_usage).to eq([1.0, 2.0, 3.0])
        expect(os_metrics).to have_received(:cpu_usage)
      end
    end

    describe '#cpus' do
      it 'delegates to os_metrics' do
        allow(os_metrics).to receive(:cpus).and_return(8)
        expect(container_metrics.cpus).to eq(8)
        expect(os_metrics).to have_received(:cpus)
      end
    end

    describe '#threads' do
      it 'delegates to os_metrics' do
        allow(os_metrics).to receive(:threads).and_return(10)
        expect(container_metrics.threads(memory_threads_ps)).to eq(10)
        expect(os_metrics).to have_received(:threads).with(memory_threads_ps)
      end
    end

    describe '#memory_threads_ps' do
      it 'delegates to os_metrics' do
        allow(os_metrics).to receive(:memory_threads_ps).and_return(memory_threads_ps)
        expect(container_metrics.memory_threads_ps).to eq(memory_threads_ps)
        expect(os_metrics).to have_received(:memory_threads_ps)
      end
    end
  end
end
