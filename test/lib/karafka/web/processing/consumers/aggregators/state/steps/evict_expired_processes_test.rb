# frozen_string_literal: true

describe_current do
  let(:ttl_seconds) { Karafka::Web.config.ttl / 1_000.0 }
  let(:aggregated_from) { 1_000_000.0 }

  let(:state) { { processes: processes } }
  let(:active_reports) { active_reports_data }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: state,
      active_reports: active_reports,
      aggregated_from: aggregated_from,
      report: {},
      offset: 1
    )
  end

  let(:step) { described_class.new(context) }

  context "when a process is older than the ttl" do
    let(:processes) { { old: { dispatched_at: aggregated_from - ttl_seconds - 10 } } }
    let(:active_reports_data) { { old: { dispatched_at: aggregated_from - ttl_seconds - 10 } } }

    it "removes it from both state[:processes] and active_reports" do
      step.call

      assert_empty(state[:processes])
      assert_empty(active_reports)
    end
  end

  context "when a process is within the ttl" do
    let(:processes) { { fresh: { dispatched_at: aggregated_from - 1 } } }
    let(:active_reports_data) { { fresh: { dispatched_at: aggregated_from - 1 } } }

    it "keeps it in both structures" do
      step.call

      assert_includes(state[:processes].keys, :fresh)
      assert_includes(active_reports.keys, :fresh)
    end
  end

  context "when a stopped process is still within the ttl" do
    let(:processes) { { stopped: { dispatched_at: aggregated_from - 1, status: "stopped" } } }
    let(:active_reports_data) do
      { stopped: { dispatched_at: aggregated_from - 1, status: "stopped" } }
    end

    it "does not evict it, since only age (not status) drives eviction" do
      step.call

      assert_includes(state[:processes].keys, :stopped)
      assert_includes(active_reports.keys, :stopped)
    end
  end
end
