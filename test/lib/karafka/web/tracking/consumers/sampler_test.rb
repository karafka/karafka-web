# frozen_string_literal: true

describe_current do
  let(:sampler) { described_class.new }

  context "when we do not run system sampling and start with empty state" do
    let(:process) { sampler.to_report[:process] }
    let(:stats) { sampler.to_report[:stats] }
    let(:versions) { sampler.to_report[:versions] }

    it { assert_includes(sampler.to_report.keys, :schema_version) }
    it { assert_equal("consumer", sampler.to_report[:type]) }
    it { refute_nil(sampler.to_report[:dispatched_at]) }
    it { assert_empty(sampler.to_report[:jobs]) }
    it { assert_empty(sampler.to_report[:consumer_groups]) }
    it { refute_nil(process[:started_at]) }
    it { assert_includes(process[:id], Socket.gethostname) }
    it { assert_equal("initialized", process[:status]) }
    it { assert_equal({ active: 0, standby: 0 }, process[:listeners]) }
    it { assert_equal(0, process[:workers]) }
    it { assert_equal(0, process[:memory_usage]) }
    it { assert_equal(0, process[:memory_total_usage]) }
    it { refute_nil(process[:memory_size]) }
    it { assert(process[:cpus] > 0) }
    it { assert_equal(0, process[:threads]) }
    it { assert_equal([-1, -1, -1], process[:cpu_usage]) }
    it { assert_equal(Karafka::Process.tags, process[:tags]) }
    it { assert_includes(versions[:ruby], "ruby") }
    it { assert_equal(Karafka::VERSION, versions[:karafka]) }
    it { assert_equal(Karafka::Core::VERSION, versions[:karafka_core]) }
    it { assert_equal(WaterDrop::VERSION, versions[:waterdrop]) }
    it { assert_equal(Rdkafka::VERSION, versions[:rdkafka]) }
    it { assert_equal(Rdkafka::LIBRDKAFKA_VERSION, versions[:librdkafka]) }
    it { assert_equal(0, stats[:busy]) }
    it { assert_equal(0, stats[:enqueued]) }
    it { assert_equal(0, stats[:utilization]) }
    it { assert_equal(0, stats[:total][:batches]) }
    it { assert_equal(0, stats[:total][:dead]) }
    it { assert_equal(0, stats[:total][:errors]) }
    it { assert_equal(0, stats[:total][:messages]) }
    it { assert_equal(0, stats[:total][:retries]) }
  end

  describe "#clear" do
    before do
      sampler.track do |sampler|
        sampler.counters[:messages] += 1
        sampler.jobs[:test] = 1
        sampler.consumer_groups[:test] = 1
        sampler.errors << 1
        sampler.pauses[:test] = 1
      end

      sampler.clear
    end

    it "expect to clear counters" do
      assert_equal(0, sampler.counters[:messages])
    end

    it "expect not to clear jobs" do
      refute_empty(sampler.jobs)
    end

    it "expect not to clear pauses" do
      refute_empty(sampler.pauses)
    end

    it "expect not to clear consumer_groups" do
      refute_empty(sampler.consumer_groups)
    end

    it "expect to clear errors" do
      assert_empty(sampler.errors)
    end
  end

  describe "#sample" do
    let(:process) { sampler.to_report[:process] }

    before { sampler.sample }

    it { refute_equal(0, process[:memory_usage]) }
    it { refute_equal(0, process[:memory_total_usage]) }
    it { refute_equal(0, process[:threads]) }
    it { refute_equal([-1, -1, -1], process[:cpu_usage]) }
  end

  describe "system metrics collector selection" do
    context "when running outside container (real behavior)" do
      it "instantiates Os metrics collector as cgroups are not available" do
        sampler = described_class.new
        # Test through public API - memory_size should work (from Os class)
        assert(sampler.to_report[:process][:memory_size] > 0)
      end
    end

    context "when cgroups are available (simulated)" do
      it "instantiates Container metrics collector" do
        Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.stubs(:active?).returns(true)
        sampler = described_class.new

        assert_kind_of(
          Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container,
          sampler.instance_variable_get(:@system_metrics)
        )
      end
    end

    context "when cgroups are not available (simulated)" do
      it "instantiates Os metrics collector" do
        Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.stubs(:active?).returns(false)
        sampler = described_class.new

        assert_kind_of(
          Karafka::Web::Tracking::Consumers::Sampler::Metrics::Os,
          sampler.instance_variable_get(:@system_metrics)
        )
      end
    end
  end
end
