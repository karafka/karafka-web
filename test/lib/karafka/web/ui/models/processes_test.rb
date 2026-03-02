# frozen_string_literal: true

describe_current do
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
    produce(reports_topic, report.to_json)
  end

  describe "#active" do
    let(:processes) { described_class.active(state) }

    context "when the requested processes from states do not exist" do
      before { state[:processes][:"shinra:1:1"][:offset] = 1_000 }

      it { assert_empty(processes) }
    end

    context "when requested processes are too old" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:dispatched_at] = 1_690_883_271
        report
      end

      it { assert_empty(processes) }
    end

    context "when requested processes are active" do
      it { refute_empty(processes) }
    end

    context "when there is a requested process with incompatible schema" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:schema_version] = "0.1"
        report
      end

      it "expect not to include them" do
        assert_empty(processes)
      end
    end
  end

  describe "#all" do
    let(:processes) { described_class.all(state) }

    context "when the requested processes from states do not exist" do
      before { state[:processes][:"shinra:1:1"][:offset] = 1_000 }

      it { assert_empty(processes) }
    end

    context "when requested processes are too old" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:dispatched_at] = 1_690_883_271
        report
      end

      it { assert_empty(processes) }
    end

    context "when requested processes are alive" do
      it { refute_empty(processes) }
    end

    context "when there is a requested process with incompatible schema" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:schema_version] = "0.1"
        report
      end

      it "expect to include them" do
        refute_empty(processes)
      end
    end
  end
end
