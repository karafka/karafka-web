# frozen_string_literal: true

describe_current do
  let(:state) { { stats: initial_stats } }
  let(:report) { { stats: { total: total } } }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: state,
      active_reports: {},
      aggregated_from: Time.now.to_f,
      report: report,
      offset: 1
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
end
