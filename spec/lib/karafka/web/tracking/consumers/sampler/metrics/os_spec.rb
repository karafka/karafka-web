# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Os do
  subject(:os_metrics) { described_class.new(shell) }

  let(:shell) { instance_double(Karafka::Web::Tracking::MemoizedShell) }

  describe '#memory_usage' do
    context 'when running on Linux' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
        allow(IO).to receive(:readlines)
          .with("/proc/#{Process.pid}/status")
          .and_return([
                        "Name:\truby\n",
                        "VmRSS:\t123456 kB\n",
                        "VmSize:\t234567 kB\n"
                      ])
      end

      it 'reads from /proc/PID/status' do
        expect(os_metrics.memory_usage).to eq(123_456)
      end
    end

    context 'when running on macOS' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-darwin')
        allow(shell).to receive(:call)
          .with("ps -o pid,rss -p #{Process.pid}")
          .and_return("  PID  RSS\n#{Process.pid} 98765\n")
      end

      it 'uses ps command' do
        expect(os_metrics.memory_usage).to eq(98_765)
      end
    end
  end

  describe '#memory_total_usage' do
    context 'when memory_threads_ps is available' do
      let(:memory_threads_ps) { [[1024, 10, 1234], [2048, 20, 5678]] }

      it 'sums up memory from all processes' do
        expect(os_metrics.memory_total_usage(memory_threads_ps)).to eq(3072)
      end
    end

    context 'when memory_threads_ps is false' do
      it 'returns 0' do
        expect(os_metrics.memory_total_usage(false)).to eq(0)
      end
    end

    context 'when memory_threads_ps is nil' do
      it 'returns 0' do
        expect(os_metrics.memory_total_usage(nil)).to eq(0)
      end
    end
  end

  describe '#memory_size' do
    context 'when running on Linux' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
        allow(File).to receive(:read)
          .with('/proc/meminfo')
          .and_return("MemTotal:       16384000 kB\nMemFree:        8192000 kB\n")
      end

      it 'reads from /proc/meminfo' do
        expect(os_metrics.memory_size).to eq(16_384_000)
      end
    end

    context 'when running on macOS' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-darwin')
        allow(shell).to receive(:call)
          .with('sysctl -a')
          .and_return("hw.memsize: 17179869184\nhw.ncpu: 8\n")
      end

      it 'uses sysctl command' do
        expect(os_metrics.memory_size).to eq(17_179_869_184)
      end
    end
  end

  describe '#cpu_usage' do
    context 'when running on Linux' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
        allow(File).to receive(:read)
          .with('/proc/loadavg')
          .and_return("1.23 4.56 7.89 2/345 12345\n")
      end

      it 'reads load averages from /proc/loadavg' do
        expect(os_metrics.cpu_usage).to eq([1.23, 4.56, 7.89])
      end
    end

    context 'when running on macOS' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-darwin')
        allow(shell).to receive(:call)
          .with('w | head -1')
          .and_return("12:34  up 5 days, 6:78, 9 users, load averages: 2.34 5.67 8.90\n")
      end

      it 'parses load averages from w command' do
        expect(os_metrics.cpu_usage).to eq([2.34, 5.67, 8.90])
      end
    end

    context 'when running on unknown platform' do
      before do
        stub_const('RUBY_PLATFORM', 'unknown')
      end

      it 'returns default values' do
        expect(os_metrics.cpu_usage).to eq([-1, -1, -1])
      end
    end
  end

  describe '#cpus' do
    it 'returns number of processors' do
      expect(os_metrics.cpus).to be > 0
      expect(os_metrics.cpus).to eq(Etc.nprocessors)
    end
  end

  describe '#threads' do
    context 'when memory_threads_ps is available' do
      let(:memory_threads_ps) { [[1024, 10, 9999], [2048, 20, Process.pid]] }

      it 'returns thread count for current process' do
        expect(os_metrics.threads(memory_threads_ps)).to eq(20)
      end
    end

    context 'when memory_threads_ps is false' do
      it 'returns 0' do
        expect(os_metrics.threads(false)).to eq(0)
      end
    end

    context 'when memory_threads_ps is nil' do
      it 'returns 0' do
        expect(os_metrics.threads(nil)).to eq(0)
      end
    end
  end

  describe '#memory_threads_ps' do
    context 'when running on Linux' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
        allow(Karafka::Web::Tracking::Helpers::Sysconf).to receive(:page_size).and_return(4096)

        # Simulate multiple processes in /proc
        proc_files = [
          '/proc/1/statm',
          "/proc/#{Process.pid}/statm",
          '/proc/9999/statm'
        ]
        allow(Dir).to receive(:glob).with('/proc/[0-9]*/statm').and_return(proc_files)

        # Stub file reads for all processes
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('/proc/1/statm').and_return("1000 500 100 0 0 400 0\n")
        allow(File).to receive(:read).with("/proc/#{Process.pid}/statm").and_return("12345 6789 1234 0 0 5678 0\n")
        allow(File).to receive(:read).with('/proc/9999/statm').and_return("2000 1000 200 0 0 800 0\n")

        # Only current process needs thread count
        allow(File).to receive(:read).with("/proc/#{Process.pid}/status").and_return("Threads:\t15\n")
      end

      it 'returns array with memory, threads, and pid for all processes' do
        result = os_metrics.memory_threads_ps
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)

        # Find current process entry
        current_process = result.find { |row| row[2] == Process.pid }
        expect(current_process).to be_an(Array)
        expect(current_process.size).to eq(3)
        expect(current_process[1]).to eq(15) # thread count only for current process
        expect(current_process[2]).to eq(Process.pid)

        # Other processes should have 0 threads
        other_processes = result.reject { |row| row[2] == Process.pid }
        expect(other_processes.all? { |row| row[1] == 0 }).to be(true)
      end
    end

    context 'when running on macOS' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-darwin')
        allow(shell).to receive(:call)
          .with('ps -A -o rss=,pid=')
          .and_return("  1024  #{Process.pid}\n  2048  9999\n")
      end

      it 'returns array with memory and pid, threads set to 0' do
        result = os_metrics.memory_threads_ps
        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        # First process
        expect(result[0][0]).to eq(1024) # memory
        expect(result[0][1]).to eq(0)    # threads (not available on macOS)
        expect(result[0][2]).to eq(Process.pid)
      end
    end

    context 'when running on unknown platform' do
      before do
        stub_const('RUBY_PLATFORM', 'unknown')
      end

      it 'returns false' do
        expect(os_metrics.memory_threads_ps).to be(false)
      end
    end
  end
end
