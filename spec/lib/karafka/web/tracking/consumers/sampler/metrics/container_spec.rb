# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container do
  subject(:container_metrics) { described_class.new(shell) }

  let(:shell) { instance_double(Karafka::Web::Tracking::MemoizedShell) }

  describe ".active?" do
    before do
      # Clear memoization before each test to avoid pollution between tests
      # This is necessary because cgroup_version is memoized at class level
      if described_class.instance_variable_defined?(:@cgroup_version)
        described_class.remove_instance_variable(:@cgroup_version)
      end
    end

    context "when checking real file system" do
      it "detects cgroup availability correctly based on actual cgroup files" do
        # Tests real file system detection without stubs
        # Result depends on whether cgroup files actually exist in the environment
        v2_exists = File.exist?("/sys/fs/cgroup/cgroup.controllers")
        v1_exists = File.exist?("/sys/fs/cgroup/memory/memory.limit_in_bytes")
        expected_result = v2_exists || v1_exists

        expect(described_class.active?).to eq(expected_result)
      end
    end

    context "when cgroup v2 is available (simulated)" do
      it "returns true" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with("/sys/fs/cgroup/cgroup.controllers")
          .and_return(true)

        expect(described_class.active?).to be(true)
      end
    end

    context "when cgroup v1 is available (simulated)" do
      it "returns true" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with("/sys/fs/cgroup/cgroup.controllers")
          .and_return(false)
        allow(File).to receive(:exist?)
          .with("/sys/fs/cgroup/memory/memory.limit_in_bytes")
          .and_return(true)

        expect(described_class.active?).to be(true)
      end
    end
  end

  describe "#memory_size" do
    context "when running outside container (real behavior)" do
      it "falls back to OS metrics since no cgroup limit exists" do
        # This tests the actual || super fallback
        expect(container_metrics.memory_size).to be > 0
      end
    end

    context "when cgroup memory limit is available (simulated)" do
      before do
        allow(described_class).to receive(:memory_limit).and_return(2 * 1024 * 1024) # 2GB in KB
      end

      it "returns cgroup memory limit" do
        expect(container_metrics.memory_size).to eq(2 * 1024 * 1024)
      end
    end

    context "when cgroup memory limit is not available (simulated)" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-linux")
        allow(described_class).to receive(:memory_limit).and_return(nil)
        allow(File).to receive(:read)
          .with("/proc/meminfo")
          .and_return("MemTotal:       16384000 kB\n")
      end

      it "falls back to OS metrics via super" do
        expect(container_metrics.memory_size).to eq(16_384_000)
      end
    end
  end

  describe "inheritance from Os" do
    it "inherits all OS metrics methods" do
      expect(container_metrics).to respond_to(:memory_usage)
      expect(container_metrics).to respond_to(:memory_total_usage)
      expect(container_metrics).to respond_to(:cpu_usage)
      expect(container_metrics).to respond_to(:cpus)
      expect(container_metrics).to respond_to(:threads)
      expect(container_metrics).to respond_to(:memory_threads_ps)
    end
  end
end
