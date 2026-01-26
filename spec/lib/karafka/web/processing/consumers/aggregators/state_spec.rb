# frozen_string_literal: true

RSpec.describe_current do
  subject(:state_aggregator) { described_class.new(schema_manager) }

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

        expect(state[:processes].keys).to include(:"process-1234")
        expect(state[:processes][:"process-1234"][:offset]).to eq(100)
        expect(state[:processes][:"process-1234"][:dispatched_at]).to eq(report[:dispatched_at])
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

        expect(process[:offset]).to eq(200)
        expect(process[:dispatched_at]).to eq(updated_report[:dispatched_at])
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

        expect(state[:processes].keys).to include(:"process-5678")
        expect(state[:processes][:"process-5678"][:offset]).to eq(300)
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
        expect(state[:processes].keys.size).to eq(1)
        expect(state[:processes][:"process-abc"][:offset]).to eq(150)
        expect(state[:processes][:"process-abc"][:dispatched_at]).to eq(new_report[:dispatched_at])
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
        expect(state[:processes][:"worker-1"][:offset]).to eq(10)
        expect(state[:processes][:"worker-2"][:offset]).to eq(20)
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
        expect(state[:processes].keys).to include(process_id)
        expect(state[:processes][process_id][:offset]).to eq(42)
      end

      it "increments total counters" do
        initial_state = state_aggregator.to_h
        initial_total = initial_state[:stats][:messages] || 0

        state_aggregator.add(report, 42)

        new_state = state_aggregator.to_h
        new_total = new_state[:stats][:messages]

        expect(new_total).to be > initial_total
      end

      it "updates stats correctly" do
        state_aggregator.add(report, 42)
        stats = state_aggregator.stats

        expect(stats).to be_a(Hash)
        expect(stats[:processes]).to eq(1)
        expect(stats[:busy]).to be >= 0
        expect(stats[:enqueued]).to be >= 0
      end
    end
  end

  describe "#to_h and #stats" do
    it "includes schema version" do
      state = state_aggregator.to_h
      expect(state[:schema_version]).to eq("1.4.0")
    end

    it "includes dispatched_at timestamp" do
      state = state_aggregator.to_h
      expect(state[:dispatched_at]).to be_a(Float)
      expect(state[:dispatched_at]).to be > 0
    end

    it "includes schema state" do
      state = state_aggregator.to_h
      expect(state[:schema_state]).to be_a(String)
    end

    it "returns a copy of the stats" do
      stats1 = state_aggregator.stats
      stats2 = state_aggregator.stats

      expect(stats1).to eq(stats2)
      expect(stats1.object_id).not_to eq(stats2.object_id)
    end
  end
end
