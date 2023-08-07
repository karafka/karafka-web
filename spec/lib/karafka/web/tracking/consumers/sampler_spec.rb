# frozen_string_literal: true

RSpec.describe_current do
  subject(:sampler) { described_class.new }

  context 'when we do not run system sampling and start with empty state' do
    let(:process) { sampler.to_report[:process] }
    let(:stats) { sampler.to_report[:stats] }
    let(:versions) { sampler.to_report[:versions] }

    it { expect(sampler.to_report.keys).to include(:schema_version) }
    it { expect(sampler.to_report[:type]).to eq('consumer') }
    it { expect(sampler.to_report[:dispatched_at]).not_to be_nil }
    it { expect(sampler.to_report[:jobs]).to be_empty }
    it { expect(sampler.to_report[:consumer_groups]).to be_empty }
    it { expect(process[:started_at]).not_to be_nil }
    it { expect(process[:name]).to include(Socket.gethostname) }
    it { expect(process[:status]).to eq('initialized') }
    it { expect(process[:listeners]).to eq(0) }
    it { expect(process[:workers]).to eq(5) }
    it { expect(process[:memory_usage]).to eq(0) }
    it { expect(process[:memory_total_usage]).to eq(0) }
    it { expect(process[:memory_size]).not_to be_nil }
    it { expect(process[:cpus]).to be > 0 }
    it { expect(process[:threads]).to eq(0) }
    it { expect(process[:cpu_usage]).to eq([-1, -1, -1]) }
    it { expect(process[:tags]).to eq(Karafka::Process.tags) }
    it { expect(versions[:ruby]).to include('ruby 3.2') }
    it { expect(versions[:karafka]).to eq(Karafka::VERSION) }
    it { expect(versions[:karafka_core]).to eq(Karafka::Core::VERSION) }
    it { expect(versions[:waterdrop]).to eq(WaterDrop::VERSION) }
    it { expect(versions[:rdkafka]).to eq(Rdkafka::VERSION) }
    it { expect(versions[:librdkafka]).to eq(Rdkafka::LIBRDKAFKA_VERSION) }
    it { expect(stats[:busy]).to eq(0) }
    it { expect(stats[:enqueued]).to eq(0) }
    it { expect(stats[:utilization]).to eq(0) }
    it { expect(stats[:total][:batches]).to eq(0) }
    it { expect(stats[:total][:dead]).to eq(0) }
    it { expect(stats[:total][:errors]).to eq(0) }
    it { expect(stats[:total][:messages]).to eq(0) }
    it { expect(stats[:total][:retries]).to eq(0) }
  end

  describe '#clear' do
    before do
      sampler.track do |sampler|
        sampler.counters[:messages] += 1
        sampler.times[:test] << 1
        sampler.jobs[:test] = 1
        sampler.consumer_groups[:test] = 1
        sampler.errors << 1
        sampler.pauses << 1
      end

      sampler.clear
    end

    it 'expect to clear counters' do
      expect(sampler.counters[:messages]).to eq(0)
    end

    it 'expect not to clear times' do
      expect(sampler.times).not_to be_empty
    end

    it 'expect not to clear jobs' do
      expect(sampler.jobs).not_to be_empty
    end

    it 'expect not to clear pauses' do
      expect(sampler.pauses).not_to be_empty
    end

    it 'expect not to clear consumer_groups' do
      expect(sampler.consumer_groups).not_to be_empty
    end

    it 'expect to clear errors' do
      expect(sampler.errors).to be_empty
    end
  end

  describe '#sample' do
    let(:process) { sampler.to_report[:process] }

    before { sampler.sample }

    it { expect(process[:memory_usage]).not_to eq(0) }
    it { expect(process[:memory_total_usage]).not_to eq(0) }
    it { expect(process[:threads]).not_to eq(0) }
    it { expect(process[:cpu_usage]).not_to eq([-1, -1, -1]) }
  end
end
