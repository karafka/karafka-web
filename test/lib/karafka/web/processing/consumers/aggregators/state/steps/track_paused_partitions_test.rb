# frozen_string_literal: true

describe_current do
  let(:aggregated_from) { 1_000_000.0 }
  let(:paused_since) { {} }
  let(:active_reports) { {} }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: {},
      active_reports: active_reports,
      aggregated_from: aggregated_from,
      report: {},
      offset: 1,
      paused_since: paused_since,
      paused_partitions_lag_refreshed_at: nil
    )
  end

  let(:step) { described_class.new(context) }

  def build_report(status: "running", poll_state: "paused", cg_id: "cg", topic: "topic", partition_id: 0)
    {
      process: { status: status },
      consumer_groups: {
        cg_id => {
          subscription_groups: {
            sg_0: {
              topics: {
                topic => {
                  partitions: {
                    partition_id => { poll_state: poll_state }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  context "when a partition is paused for the first time" do
    let(:active_reports) { { p1: build_report } }

    it "records the current aggregated_from as the moment it started being paused" do
      step.call

      assert_equal(aggregated_from, paused_since[["cg", "topic", 0]])
    end
  end

  context "when a partition has already been observed as paused" do
    let(:paused_since) { { ["cg", "topic", 0] => 900_000.0 } }
    let(:active_reports) { { p1: build_report } }

    it "keeps the original first-seen timestamp rather than overwriting it" do
      step.call

      assert_in_delta(900_000.0, paused_since[["cg", "topic", 0]])
    end
  end

  context "when a previously paused partition is no longer paused" do
    let(:paused_since) { { ["cg", "topic", 0] => 900_000.0 } }
    let(:active_reports) { { p1: build_report(poll_state: "active") } }

    it "clears the bookkeeping entry" do
      step.call

      refute_includes(paused_since.keys, ["cg", "topic", 0])
    end
  end

  context "when a previously paused partition is no longer reported at all" do
    let(:paused_since) { { ["cg", "topic", 0] => 900_000.0 } }
    let(:active_reports) { {} }

    it "clears the bookkeeping entry" do
      step.call

      assert_empty(paused_since)
    end
  end

  context "when the reporting process has stopped" do
    let(:paused_since) { { ["cg", "topic", 0] => 900_000.0 } }
    let(:active_reports) { { p1: build_report(status: "stopped") } }

    it "does not consider its partitions as currently paused" do
      step.call

      assert_empty(paused_since)
    end
  end
end
