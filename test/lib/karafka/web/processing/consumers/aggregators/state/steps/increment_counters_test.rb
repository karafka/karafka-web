# frozen_string_literal: true

describe_current do
  let(:state) { { stats: initial_stats, processes: processes } }
  let(:report) { { process: { id: "process-1" }, stats: { total: total } } }
  let(:processes) { {} }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: state,
      active_reports: {},
      aggregated_from: Time.now.to_f,
      report: report,
      offset: 10
    )
  end

  let(:step) { described_class.new(context) }

  context "when the key already exists in state" do
    let(:initial_stats) { { batches: 3 } }
    let(:total) { { batches: 2 } }

    it "increments the existing value rather than overwriting it" do
      step.call

      assert_equal(5, state[:stats][:batches])
    end
  end

  context "when the key has never been seen before" do
    let(:initial_stats) { {} }
    let(:total) { { new_metric: 1 } }

    it "initializes it via the zero-default path" do
      step.call

      assert_equal(1, state[:stats][:new_metric])
    end
  end

  context "with multiple keys in the report total" do
    let(:initial_stats) { { batches: 1, messages: 10 } }
    let(:total) { { batches: 1, messages: 5, errors: 1 } }

    it "increments every key present in the report" do
      step.call

      assert_equal(2, state[:stats][:batches])
      assert_equal(15, state[:stats][:messages])
      assert_equal(1, state[:stats][:errors])
    end
  end

  context "when the state already holds this report of the process" do
    let(:initial_stats) { { batches: 3 } }
    let(:total) { { batches: 2 } }
    let(:processes) { { "process-1": { dispatched_at: Time.now.to_f, offset: 10 } } }

    it "does not count it again" do
      step.call

      assert_equal(3, state[:stats][:batches])
    end
  end

  context "when the state already holds a newer report of the process" do
    let(:initial_stats) { { batches: 3 } }
    let(:total) { { batches: 2 } }
    let(:processes) { { "process-1": { dispatched_at: Time.now.to_f, offset: 11 } } }

    it "does not count it again" do
      step.call

      assert_equal(3, state[:stats][:batches])
    end
  end

  context "when the state holds an older report of the process" do
    let(:initial_stats) { { batches: 3 } }
    let(:total) { { batches: 2 } }
    let(:processes) { { "process-1": { dispatched_at: Time.now.to_f, offset: 9 } } }

    it "counts it" do
      step.call

      assert_equal(5, state[:stats][:batches])
    end
  end
end
