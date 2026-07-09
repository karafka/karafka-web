# frozen_string_literal: true

describe_current do
  let(:state) { { processes: {}, stats: {} } }
  let(:active_reports) { {} }
  let(:aggregated_from) { 123.456 }
  let(:report) { { process: { id: "p1" } } }
  let(:offset) { 42 }

  let(:context) do
    described_class.new(
      state: state,
      active_reports: active_reports,
      aggregated_from: aggregated_from,
      report: report,
      offset: offset
    )
  end

  describe "readers" do
    it { assert_same(state, context.state) }
    it { assert_same(active_reports, context.active_reports) }
    it { assert_equal(aggregated_from, context.aggregated_from) }
    it { assert_same(report, context.report) }
    it { assert_equal(offset, context.offset) }
  end

  describe "mutation visibility" do
    it "exposes state/active_reports as the same mutable objects across reads" do
      context.state[:processes][:p1] = { offset: 1 }

      assert_equal({ p1: { offset: 1 } }, state[:processes])
    end
  end
end
