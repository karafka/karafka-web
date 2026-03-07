# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Os do
  let(:shell) { stub() }

  # Create a fresh instance for each test to avoid Mocha cross-test stubbing errors
  def os_metrics
    @os_metrics ||= described_class.new(shell)
  end

  before { @os_metrics = nil }

  describe "#memory_usage" do
    context "when running on Linux" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-linux")
        IO.stubs(:readlines).with("/proc/#{Process.pid}/status").returns([
            "Name:\truby\n",
            "VmRSS:\t123456 kB\n",
            "VmSize:\t234567 kB\n"
          ])
      end

      it "reads from /proc/PID/status" do
        assert_equal(123_456, os_metrics.memory_usage)
      end
    end

    context "when running on macOS" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-darwin")
        shell.stubs(:call).with("ps -o pid,rss -p #{Process.pid}").returns("  PID  RSS\n#{Process.pid} 98765\n")
      end

      it "uses ps command" do
        assert_equal(98_765, os_metrics.memory_usage)
      end
    end
  end

  describe "#memory_total_usage" do
    context "when memory_threads_ps is available" do
      let(:memory_threads_ps) { [[1024, 10, 1234], [2048, 20, 5678]] }

      it "sums up memory from all processes" do
        assert_equal(3072, os_metrics.memory_total_usage(memory_threads_ps))
      end
    end

    context "when memory_threads_ps is false" do
      it "returns 0" do
        assert_equal(0, os_metrics.memory_total_usage(false))
      end
    end

    context "when memory_threads_ps is nil" do
      it "returns 0" do
        assert_equal(0, os_metrics.memory_total_usage(nil))
      end
    end
  end

  describe "#memory_size" do
    context "when running on Linux" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-linux")
        File.stubs(:read).with("/proc/meminfo").returns("MemTotal:       16384000 kB\nMemFree:        8192000 kB\n")
      end

      it "reads from /proc/meminfo" do
        assert_equal(16_384_000, os_metrics.memory_size)
      end
    end

    context "when running on macOS" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-darwin")
        shell.stubs(:call).with("sysctl -a").returns("hw.memsize: 17179869184\nhw.ncpu: 8\n")
      end

      it "uses sysctl command" do
        assert_equal(17_179_869_184, os_metrics.memory_size)
      end
    end
  end

  describe "#cpu_usage" do
    context "when running on Linux" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-linux")
        File.stubs(:read).with("/proc/loadavg").returns("1.23 4.56 7.89 2/345 12345\n")
      end

      it "reads load averages from /proc/loadavg" do
        assert_equal([1.23, 4.56, 7.89], os_metrics.cpu_usage)
      end
    end

    context "when running on macOS" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-darwin")
        shell.stubs(:call).with("w | head -1").returns("12:34  up 5 days, 6:78, 9 users, load averages: 2.34 5.67 8.90\n")
      end

      it "parses load averages from w command" do
        assert_equal([2.34, 5.67, 8.90], os_metrics.cpu_usage)
      end
    end

    context "when running on unknown platform" do
      before do
        stub_const("RUBY_PLATFORM", "unknown")
      end

      it "returns default values" do
        assert_equal([-1, -1, -1], os_metrics.cpu_usage)
      end
    end
  end

  describe "#cpus" do
    it "returns number of processors" do
      assert(os_metrics.cpus > 0)
      assert_equal(Etc.nprocessors, os_metrics.cpus)
    end
  end

  describe "#threads" do
    context "when memory_threads_ps is available" do
      let(:memory_threads_ps) { [[1024, 10, 9999], [2048, 20, Process.pid]] }

      it "returns thread count for current process" do
        assert_equal(20, os_metrics.threads(memory_threads_ps))
      end
    end

    context "when memory_threads_ps is false" do
      it "returns 0" do
        assert_equal(0, os_metrics.threads(false))
      end
    end

    context "when memory_threads_ps is nil" do
      it "returns 0" do
        assert_equal(0, os_metrics.threads(nil))
      end
    end
  end

  describe "#memory_threads_ps" do
    context "when running on Linux" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-linux")

        Karafka::Web::Tracking::Helpers::Sysconf.stubs(:page_size).returns(4096)

        # Simulate multiple processes in /proc
        proc_files = [
          "/proc/1/statm",
          "/proc/#{Process.pid}/statm",
          "/proc/9999/statm"
        ]
        Dir.stubs(:glob).with("/proc/[0-9]*/statm").returns(proc_files)

        # Stub file reads for all processes
        stub_and_passthrough(File, :read)

        File.stubs(:read).with("/proc/1/statm").returns("1000 500 100 0 0 400 0\n")

        File.stubs(:read).with("/proc/#{Process.pid}/statm").returns("12345 6789 1234 0 0 5678 0\n")

        File.stubs(:read).with("/proc/9999/statm").returns("2000 1000 200 0 0 800 0\n")

        # Only current process needs thread count
        File.stubs(:read).with("/proc/#{Process.pid}/status").returns("Threads:\t15\n")
      end

      it "returns array with memory, threads, and pid for all processes" do
        result = os_metrics.memory_threads_ps

        assert_kind_of(Array, result)
        assert_equal(3, result.size)

        # Find current process entry
        current_process = result.find { |row| row[2] == Process.pid }

        assert_kind_of(Array, current_process)
        assert_equal(3, current_process.size)
        assert_equal(15, current_process[1]) # thread count only for current process
        assert_equal(Process.pid, current_process[2])

        # Other processes should have 0 threads
        other_processes = result.reject { |row| row[2] == Process.pid }

        assert(other_processes.all? { |row| row[1] == 0 })
      end
    end

    context "when running on macOS" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-darwin")
        shell.stubs(:call).with("ps -A -o rss=,pid=").returns("  1024  #{Process.pid}\n  2048  9999\n")
      end

      it "returns array with memory and pid, threads set to 0" do
        result = os_metrics.memory_threads_ps

        assert_kind_of(Array, result)
        assert_equal(2, result.size)
        # First process
        assert_equal(1024, result[0][0]) # memory
        assert_equal(0, result[0][1])    # threads (not available on macOS)
        assert_equal(Process.pid, result[0][2])
      end
    end

    context "when running on unknown platform" do
      before do
        stub_const("RUBY_PLATFORM", "unknown")
      end

      it "returns false" do
        refute(os_metrics.memory_threads_ps)
      end
    end
  end
end
