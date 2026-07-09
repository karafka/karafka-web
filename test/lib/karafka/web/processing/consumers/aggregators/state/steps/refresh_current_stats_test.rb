# frozen_string_literal: true

describe_current do
  let(:state) { { stats: {} } }
  let(:active_reports) { {} }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: state,
      active_reports: active_reports,
      aggregated_from: Time.now.to_f,
      report: {},
      offset: 1,
      paused_since: {},
      paused_partitions_lag_refreshed_at: nil
    )
  end

  let(:step) { described_class.new(context) }

  def build_report(status: "running", busy: 0, enqueued: 0, lag: 5, lag_stored: 10)
    {
      process: {
        status: status,
        workers: 1,
        memory_usage: 100,
        listeners: { active: 1, standby: 0 }
      },
      stats: {
        busy: busy,
        enqueued: enqueued,
        utilization: 1.0
      },
      consumer_groups: {
        cg: {
          subscription_groups: {
            sg: {
              topics: {
                topic: {
                  partitions: {
                    0 => { lag: lag, lag_stored: lag_stored }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  context "with two active (non-stopped) reports" do
    let(:active_reports) do
      {
        p1: build_report(busy: 2, enqueued: 1),
        p2: build_report(busy: 3, enqueued: 4)
      }
    end

    it "sums their stats" do
      step.call

      assert_equal(5, state[:stats][:busy])
      assert_equal(5, state[:stats][:enqueued])
      assert_equal(2, state[:stats][:processes])
    end
  end

  context "when one report has status stopped" do
    let(:active_reports) do
      {
        p1: build_report(status: "running", busy: 2, enqueued: 1),
        p2: build_report(status: "stopped", busy: 100, enqueued: 100)
      }
    end

    it "excludes the stopped report from every sum" do
      step.call

      assert_equal(2, state[:stats][:busy])
      assert_equal(1, state[:stats][:enqueued])
      assert_equal(1, state[:stats][:processes])
    end
  end

  context "with zero active reports" do
    let(:active_reports) { {} }

    it "does not raise and resets all counters to zero" do
      step.call

      assert_equal(0, state[:stats][:busy])
      assert_equal(0, state[:stats][:enqueued])
      assert_equal(0, state[:stats][:processes])
      assert_in_delta(0.0, state[:stats][:utilization])
    end
  end

  context "when computing utilization across active reports" do
    let(:active_reports) do
      {
        p1: build_report,
        p2: build_report,
        p3: build_report
      }
    end

    def build_report(utilization: 3.0, **kwargs)
      report = super(**kwargs)
      report[:stats][:utilization] = utilization
      report
    end

    it "divides exactly, without an epsilon-induced underestimate" do
      step.call

      assert_in_delta(3.0, state[:stats][:utilization])
    end
  end
end
