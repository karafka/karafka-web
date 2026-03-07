# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container do
  let(:shell) { stub() }

  # Create a fresh instance for each test to avoid Mocha cross-test stubbing errors
  def container_metrics
    @container_metrics ||= described_class.new(shell)
  end

  before { @container_metrics = nil }

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

        assert_equal(expected_result, described_class.active?)
      end
    end

    context "when cgroup v2 is available (simulated)" do
      it "returns true" do
        stub_and_passthrough(File, :exist?)
        File.stubs(:exist?).with("/sys/fs/cgroup/cgroup.controllers").returns(true)

        assert(described_class.active?)
      end
    end

    context "when cgroup v1 is available (simulated)" do
      it "returns true" do
        stub_and_passthrough(File, :exist?)
        File.stubs(:exist?).with("/sys/fs/cgroup/cgroup.controllers").returns(false)
        File.stubs(:exist?).with("/sys/fs/cgroup/memory/memory.limit_in_bytes").returns(true)

        assert(described_class.active?)
      end
    end
  end

  describe "#memory_size" do
    context "when running outside container (real behavior)" do
      it "falls back to OS metrics since no cgroup limit exists" do
        # This tests the actual || super fallback
        assert(container_metrics.memory_size > 0)
      end
    end

    context "when cgroup memory limit is available (simulated)" do
      before do
        described_class.stubs(:memory_limit).returns(2 * 1024 * 1024) # 2GB in KB
      end

      it "returns cgroup memory limit" do
        assert_equal(2 * 1024 * 1024, container_metrics.memory_size)
      end
    end

    context "when cgroup memory limit is not available (simulated)" do
      before do
        stub_const("RUBY_PLATFORM", "x86_64-linux")
        described_class.stubs(:memory_limit).returns(nil)
        File.stubs(:read).with("/proc/meminfo").returns("MemTotal:       16384000 kB\n")
      end

      it "falls back to OS metrics via super" do
        assert_equal(16_384_000, container_metrics.memory_size)
      end
    end
  end

  describe "inheritance from Os" do
    it "inherits all OS metrics methods" do
      assert_respond_to(container_metrics, :memory_usage)
      assert_respond_to(container_metrics, :memory_total_usage)
      assert_respond_to(container_metrics, :cpu_usage)
      assert_respond_to(container_metrics, :cpus)
      assert_respond_to(container_metrics, :threads)
      assert_respond_to(container_metrics, :memory_threads_ps)
    end
  end
end
