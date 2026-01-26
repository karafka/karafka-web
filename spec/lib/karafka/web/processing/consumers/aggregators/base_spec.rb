# frozen_string_literal: true

RSpec.describe_current do
  subject(:aggregator) { described_class.new }

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
      expect(aggregator).to be_a(described_class)
    end

    it "includes time helpers" do
      expect(aggregator).to respond_to(:monotonic_now)
      expect(aggregator).to respond_to(:float_now)
    end
  end

  describe "#add" do
    it "accepts a report without raising errors" do
      expect { aggregator.add(report1) }.not_to raise_error
    end

    it "accepts multiple reports" do
      expect { aggregator.add(report1) }.not_to raise_error
      expect { aggregator.add(report2) }.not_to raise_error
      expect { aggregator.add(report3) }.not_to raise_error
    end

    it "handles reports with same process id" do
      expect { aggregator.add(report1) }.not_to raise_error
      expect { aggregator.add(report3) }.not_to raise_error
    end

    it "handles reports with different process ids" do
      expect { aggregator.add(report1) }.not_to raise_error
      expect { aggregator.add(report2) }.not_to raise_error
    end

    context "with various dispatch times" do
      it "accepts reports with past dispatch times" do
        past_report = {
          process: { id: "process-past" },
          dispatched_at: Time.now.to_f - 1000
        }
        expect { aggregator.add(past_report) }.not_to raise_error
      end

      it "accepts reports with current dispatch times" do
        current_report = {
          process: { id: "process-current" },
          dispatched_at: Time.now.to_f
        }
        expect { aggregator.add(current_report) }.not_to raise_error
      end

      it "accepts reports with future dispatch times" do
        future_report = {
          process: { id: "process-future" },
          dispatched_at: Time.now.to_f + 1000
        }
        expect { aggregator.add(future_report) }.not_to raise_error
      end
    end

    context "with different report structures" do
      it "handles minimal valid report structure" do
        minimal_report = {
          process: { id: "minimal" },
          dispatched_at: 123.456
        }
        expect { aggregator.add(minimal_report) }.not_to raise_error
      end

      it "handles reports with additional data" do
        extended_report = {
          process: { id: "extended", name: "test", pid: 12_345 },
          dispatched_at: Time.now.to_f,
          extra_field: "additional data"
        }
        expect { aggregator.add(extended_report) }.not_to raise_error
      end
    end

    context "with rapid succession of reports" do
      it "handles multiple reports added quickly" do
        10.times do |i|
          report = {
            process: { id: "process-#{i}" },
            dispatched_at: Time.now.to_f + i
          }
          expect { aggregator.add(report) }.not_to raise_error
        end
      end

      it "handles overwriting reports for same process" do
        5.times do |i|
          report = {
            process: { id: "same-process" },
            dispatched_at: Time.now.to_f + i
          }
          expect { aggregator.add(report) }.not_to raise_error
        end
      end
    end
  end

  describe "time helpers inclusion" do
    it "provides monotonic_now method" do
      expect(aggregator.monotonic_now).to be_a(Float)
    end

    it "provides float_now method" do
      expect(aggregator.float_now).to be_a(Float)
    end

    it "returns increasing monotonic time" do
      time1 = aggregator.monotonic_now
      sleep(0.001)
      time2 = aggregator.monotonic_now
      expect(time2).to be > time1
    end
  end
end
