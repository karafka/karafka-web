# frozen_string_literal: true

describe Karafka::Web::Tracking::Consumers::Sampler::Metrics::Jobs do
  let(:jobs_metrics) { described_class.new(windows, started_at, workers) }

  let(:windows) { Karafka::Web::Tracking::Helpers::Ttls::Windows.new }
  let(:started_at) { Time.now.to_f }
  let(:workers) { 5 }

  describe "#utilization" do
    context "when there are no processed totals" do
      before do
        allow(jobs_metrics).to receive(:float_now).and_return(started_at + 120)
      end

      it "returns 0" do
        assert_equal(0, jobs_metrics.utilization)
      end
    end

    context "when process has been running for less than 60 seconds" do
      before do
        windows.m1[:processed_total_time] << 15_000
        windows.m1[:processed_total_time] << 20_000
        windows.m1[:processed_total_time] << 25_000
        allow(jobs_metrics).to receive(:float_now).and_return(started_at + 30)
      end

      it "uses actual runtime as timefactor" do
        # Total time: 60,000ms = 60s
        # Workers: 5
        # Timefactor: 30s (actual runtime)
        # Utilization: (60,000 / 1,000 / 5 / 30) * 100 = 40%
        assert_in_delta(40.0, jobs_metrics.utilization)
      end
    end

    context "when calculating utilization with processed time" do
      before do
        windows.m1[:processed_total_time] << 15_000
        windows.m1[:processed_total_time] << 20_000
        allow(jobs_metrics).to receive(:float_now).and_return(started_at + 60)
      end

      it "calculates utilization percentage based on worker time" do
        # Utilization should be between 0 and 100
        utilization = jobs_metrics.utilization

        assert_operator(utilization, :>=, 0)
        assert_operator(utilization, :<=, 100)
        assert_operator(utilization, :>, 0) # We added work, so it should not be 0
      end

      it "rounds to 2 decimal places" do
        utilization = jobs_metrics.utilization
        # Check that it's rounded to at most 2 decimal places
        assert_equal((utilization * 100).to_i, (utilization * 100).round)
      end
    end
  end

  describe "#jobs_queue_statistics" do
    context "when jobs queue is available with all statistics" do
      let(:queue) { instance_double(Karafka::Processing::JobsQueue) }

      before do
        allow(Karafka::Server).to receive(:jobs_queue).and_return(queue)
        allow(queue).to receive(:statistics).and_return(
          busy: 3,
          enqueued: 5,
          waiting: 2,
          other_stat: 100
        )
      end

      it "returns only relevant statistics" do
        expect(jobs_metrics.jobs_queue_statistics).to eq(
          busy: 3,
          enqueued: 5,
          waiting: 2
        )
      end
    end

    context "when jobs queue is available without waiting stat" do
      let(:queue) { instance_double(Karafka::Processing::JobsQueue) }

      before do
        allow(Karafka::Server).to receive(:jobs_queue).and_return(queue)
        allow(queue).to receive(:statistics).and_return(
          busy: 3,
          enqueued: 5
        )
      end

      it "defaults waiting to 0" do
        expect(jobs_metrics.jobs_queue_statistics).to eq(
          busy: 3,
          enqueued: 5,
          waiting: 0
        )
      end
    end

    context "when jobs queue is not available" do
      before do
        allow(Karafka::Server).to receive(:jobs_queue).and_return(nil)
      end

      it "returns default statistics" do
        expect(jobs_metrics.jobs_queue_statistics).to eq(
          busy: 0,
          enqueued: 0,
          waiting: 0
        )
      end
    end

    context "when jobs queue is available but statistics is nil" do
      let(:queue) { instance_double(Karafka::Processing::JobsQueue) }

      before do
        allow(Karafka::Server).to receive(:jobs_queue).and_return(queue)
        allow(queue).to receive(:statistics).and_return(nil)
      end

      it "returns default statistics" do
        expect(jobs_metrics.jobs_queue_statistics).to eq(
          busy: 0,
          enqueued: 0,
          waiting: 0
        )
      end
    end
  end
end
