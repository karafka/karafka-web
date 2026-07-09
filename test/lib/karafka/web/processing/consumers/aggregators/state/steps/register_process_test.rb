# frozen_string_literal: true

describe_current do
  let(:state) { { processes: {} } }
  let(:active_reports) { {} }
  let(:offset) { 100 }

  let(:report) do
    {
      process: {
        id: process_id,
        status: "running"
      },
      dispatched_at: dispatched_at
    }
  end

  let(:dispatched_at) { Time.now.to_f }

  let(:context) do
    Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
      state: state,
      active_reports: active_reports,
      aggregated_from: dispatched_at,
      report: report,
      offset: offset
    )
  end

  let(:step) { described_class.new(context) }

  context "when process id is a string" do
    let(:process_id) { "process-1234" }

    it "registers the process under a symbolized key" do
      step.call

      assert_includes(state[:processes].keys, :"process-1234")
      assert_equal(100, state[:processes][:"process-1234"][:offset])
      assert_equal(dispatched_at, state[:processes][:"process-1234"][:dispatched_at])
    end

    it "updates an existing process entry in place rather than duplicating it" do
      step.call

      updated_report = report.dup
      updated_report[:dispatched_at] = dispatched_at + 10

      updated_context = Karafka::Web::Processing::Consumers::Aggregators::State::Context.new(
        state: state,
        active_reports: active_reports,
        aggregated_from: updated_report[:dispatched_at],
        report: updated_report,
        offset: 200
      )

      described_class.new(updated_context).call

      assert_equal(1, state[:processes].size)
      assert_equal(200, state[:processes][:"process-1234"][:offset])
      assert_equal(updated_report[:dispatched_at], state[:processes][:"process-1234"][:dispatched_at])
    end
  end

  context "when process id is already a symbol" do
    let(:process_id) { :"process-5678" }

    it "keeps the process id as a symbol" do
      step.call

      assert_includes(state[:processes].keys, :"process-5678")
      assert_equal(100, state[:processes][:"process-5678"][:offset])
    end
  end
end
