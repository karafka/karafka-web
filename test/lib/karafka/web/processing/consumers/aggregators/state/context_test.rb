# frozen_string_literal: true

describe_current do
  let(:state) { { processes: {}, stats: {} } }
  let(:active_reports) { {} }
  let(:aggregated_from) { 123.456 }
  let(:report) { { process: { id: "p1" } } }
  let(:offset) { 42 }
  let(:paused_since) { {} }
  let(:paused_partitions_lag_refreshed_at) { nil }

  let(:context) do
    described_class.new(
      state: state,
      active_reports: active_reports,
      aggregated_from: aggregated_from,
      report: report,
      offset: offset,
      paused_since: paused_since,
      paused_partitions_lag_refreshed_at: paused_partitions_lag_refreshed_at
    )
  end

  describe "readers" do
    it { assert_same(state, context.state) }
    it { assert_same(active_reports, context.active_reports) }
    it { assert_equal(aggregated_from, context.aggregated_from) }
    it { assert_same(report, context.report) }
    it { assert_equal(offset, context.offset) }
    it { assert_same(paused_since, context.paused_since) }
    it { assert_nil(context.paused_partitions_lag_refreshed_at) }
  end

  describe "mutation visibility" do
    it "exposes state/active_reports as the same mutable objects across reads" do
      context.state[:processes][:p1] = { offset: 1 }

      assert_equal({ p1: { offset: 1 } }, state[:processes])
    end

    it "exposes paused_since as the same mutable object across reads" do
      context.paused_since[[:cg, :topic, 0]] = 100.0

      assert_equal({ [:cg, :topic, 0] => 100.0 }, paused_since)
    end
  end

  describe "paused_partitions_lag_refreshed_at writer" do
    it "allows reassignment, since it is a scalar throttle timestamp" do
      context.paused_partitions_lag_refreshed_at = 456.789

      assert_in_delta(456.789, context.paused_partitions_lag_refreshed_at)
    end
  end
end
