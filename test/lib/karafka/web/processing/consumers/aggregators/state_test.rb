# frozen_string_literal: true

describe_current do
  let(:state_aggregator) { described_class.new(schema_manager) }

  let(:schema_manager) { Karafka::Web::Processing::Consumers::SchemaManager.new }
  let(:reports_topic) { Karafka::Web.config.topics.consumers.reports.name = create_topic }
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics.name = create_topic }
  let(:states_topic) { Karafka::Web.config.topics.consumers.states.name = create_topic }

  before do
    reports_topic
    metrics_topic
    states_topic

    Karafka::Web::Management::Actions::CreateInitialStates.new.call
    Karafka::Web::Management::Actions::MigrateStatesData.new.call
  end

  describe "#add_state" do
    context "when process id is a string" do
      let(:report) do
        {
          process: {
            id: "process-1234",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "converts process id to symbol as key" do
        state_aggregator.add_state(report, 100)
        state = state_aggregator.to_h

        assert_includes(state[:processes].keys, :"process-1234")
        assert_equal(100, state[:processes][:"process-1234"][:offset])
        assert_equal(report[:dispatched_at], state[:processes][:"process-1234"][:dispatched_at])
      end

      it "allows updating existing process with string id" do
        # First add
        state_aggregator.add_state(report, 100)

        # Update with new offset
        updated_report = report.dup
        updated_report[:dispatched_at] = Time.now.to_f + 10
        state_aggregator.add_state(updated_report, 200)

        state = state_aggregator.to_h
        process = state[:processes][:"process-1234"]

        assert_equal(200, process[:offset])
        assert_equal(updated_report[:dispatched_at], process[:dispatched_at])
      end
    end

    context "when process id is already a symbol" do
      let(:report) do
        {
          process: {
            id: :"process-5678",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "keeps process id as symbol" do
        state_aggregator.add_state(report, 300)
        state = state_aggregator.to_h

        assert_includes(state[:processes].keys, :"process-5678")
        assert_equal(300, state[:processes][:"process-5678"][:offset])
      end
    end

    context "when updating state from deserialized data" do
      let(:initial_report) do
        {
          process: {
            id: "process-abc",
            status: "running"
          },
          dispatched_at: Time.now.to_f - 100
        }
      end

      let(:new_report) do
        {
          process: {
            id: "process-abc",
            status: "running"
          },
          dispatched_at: Time.now.to_f
        }
      end

      before do
        # Simulate existing state with symbolized keys
        state_aggregator.add_state(initial_report, 50)
      end

      it "correctly updates existing process when keys are already symbols" do
        # This tests the scenario described in the comment where we have
        # deserialized state with symbol keys and need to update it
        state_aggregator.add_state(new_report, 150)

        state = state_aggregator.to_h
        # Should have only one process, not two
        assert_equal(1, state[:processes].keys.size)
        assert_equal(150, state[:processes][:"process-abc"][:offset])
        assert_equal(new_report[:dispatched_at], state[:processes][:"process-abc"][:dispatched_at])
      end
    end

    context "with multiple processes" do
      let(:process1_report) do
        {
          process: {
            id: "worker-1",
            status: "running"
          },
          dispatched_at: Time.now.to_f - 10
        }
      end

      let(:process2_report) do
        {
          process: {
            id: "worker-2",
            status: "running"
          },
          dispatched_at: Time.now.to_f - 5
        }
      end

      it "maintains separate entries for different processes" do
        state_aggregator.add_state(process1_report, 10)
        state_aggregator.add_state(process2_report, 20)

        state = state_aggregator.to_h

        expect(state[:processes].keys).to contain_exactly(:"worker-1", :"worker-2")
        assert_equal(10, state[:processes][:"worker-1"][:offset])
        assert_equal(20, state[:processes][:"worker-2"][:offset])
      end
    end
  end

  describe "#add" do
    context "when adding a complete report with string process id" do
      let(:report) do
        data = Fixtures.consumers_reports_json("multi_partition/v1.4.1_process_1")
        data[:dispatched_at] = Time.now.to_f
        # Ensure the process id is a string to test the conversion
        data[:process][:id] = data[:process][:id].to_s
        data
      end

      it "processes the report correctly with symbolized process id" do
        state_aggregator.add(report, 42)
        state = state_aggregator.to_h

        process_id = report[:process][:id].to_sym
        assert_includes(state[:processes].keys, process_id)
        assert_equal(42, state[:processes][process_id][:offset])
      end

      it "increments total counters" do
        initial_state = state_aggregator.to_h
        initial_total = initial_state[:stats][:messages] || 0

        state_aggregator.add(report, 42)

        new_state = state_aggregator.to_h
        new_total = new_state[:stats][:messages]

        assert_operator(new_total, :>, initial_total)
      end

      it "updates stats correctly" do
        state_aggregator.add(report, 42)
        stats = state_aggregator.stats

        assert_kind_of(Hash, stats)
        assert_equal(1, stats[:processes])
        assert_operator(stats[:busy], :>=, 0)
        assert_operator(stats[:enqueued], :>=, 0)
      end
    end
  end

  describe "#to_h and #stats" do
    it "includes schema version" do
      state = state_aggregator.to_h
      assert_equal("1.4.0", state[:schema_version])
    end

    it "includes dispatched_at timestamp" do
      state = state_aggregator.to_h
      assert_kind_of(Float, state[:dispatched_at])
      assert_operator(state[:dispatched_at], :>, 0)
    end

    it "includes schema state" do
      state = state_aggregator.to_h
      assert_kind_of(String, state[:schema_state])
    end

    it "returns a copy of the stats" do
      stats1 = state_aggregator.stats
      stats2 = state_aggregator.stats

      assert_equal(stats2, stats1)
      refute_equal(stats2.object_id, stats1.object_id)
    end
  end
end
