# frozen_string_literal: true

describe_current do
  let(:aggregator) { described_class.new }

  let(:report1) do
    {
      process: { id: "process-1" },
      dispatched_at: Time.now.to_f - 10
    }
  end

  let(:report2) do
    {
      process: { id: "process-2" },
      dispatched_at: Time.now.to_f - 5
    }
  end

  let(:report3) do
    {
      process: { id: "process-1" },
      dispatched_at: Time.now.to_f
    }
  end

  describe "#initialize" do
    it "creates a new aggregator instance" do
      assert_kind_of(described_class, aggregator)
    end

    it "includes time helpers" do
      assert_respond_to(aggregator, :monotonic_now)
      assert_respond_to(aggregator, :float_now)
    end
  end

  describe "#add" do
    it "accepts a report without raising errors" do
      aggregator.add(report1)
    end

    it "accepts multiple reports" do
      aggregator.add(report1)
      aggregator.add(report2)
      aggregator.add(report3)
    end

    it "handles reports with same process id" do
      aggregator.add(report1)
      aggregator.add(report3)
    end

    it "handles reports with different process ids" do
      aggregator.add(report1)
      aggregator.add(report2)
    end

    context "with various dispatch times" do
      it "accepts reports with past dispatch times" do
        past_report = {
          process: { id: "process-past" },
          dispatched_at: Time.now.to_f - 1000
        }
        aggregator.add(past_report)
      end

      it "accepts reports with current dispatch times" do
        current_report = {
          process: { id: "process-current" },
          dispatched_at: Time.now.to_f
        }
        aggregator.add(current_report)
      end

      it "accepts reports with future dispatch times" do
        future_report = {
          process: { id: "process-future" },
          dispatched_at: Time.now.to_f + 1000
        }
        aggregator.add(future_report)
      end
    end

    context "with different report structures" do
      it "handles minimal valid report structure" do
        minimal_report = {
          process: { id: "minimal" },
          dispatched_at: 123.456
        }
        aggregator.add(minimal_report)
      end

      it "handles reports with additional data" do
        extended_report = {
          process: { id: "extended", name: "test", pid: 12_345 },
          dispatched_at: Time.now.to_f,
          extra_field: "additional data"
        }
        aggregator.add(extended_report)
      end
    end

    context "with rapid succession of reports" do
      it "handles multiple reports added quickly" do
        10.times do |i|
          report = {
            process: { id: "process-#{i}" },
            dispatched_at: Time.now.to_f + i
          }
          aggregator.add(report)
        end
      end

      it "handles overwriting reports for same process" do
        5.times do |i|
          report = {
            process: { id: "same-process" },
            dispatched_at: Time.now.to_f + i
          }
          aggregator.add(report)
        end
      end
    end
  end

  describe "time helpers inclusion" do
    it "provides monotonic_now method" do
      assert_kind_of(Float, aggregator.monotonic_now)
    end

    it "provides float_now method" do
      assert_kind_of(Float, aggregator.float_now)
    end

    it "returns increasing monotonic time" do
      time1 = aggregator.monotonic_now
      sleep(0.001)
      time2 = aggregator.monotonic_now
      assert_operator(time2, :>, time1)
    end
  end
end
