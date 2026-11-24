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

  describe "#by_member_id" do
    let(:mapping) { described_class.by_member_id(state) }
    let(:subscription_groups) do
      report[:consumer_groups].values.flat_map { |cg| cg[:subscription_groups].values }
    end

    context "when the processes report member ids" do
      it "maps each of them to its process and subscription group" do
        assert_equal(
          %w[
            karafka-1c5e2b3a-7d4f-4e8a-b6c9-0f2a3d4e5b6c
            my-static-instance-8b1f6c2e-3f2d-4a8e-9c1b-2d7e5f4a9b10
          ],
          mapping.keys.sort
        )

        membership = mapping.fetch("karafka-1c5e2b3a-7d4f-4e8a-b6c9-0f2a3d4e5b6c")

        assert_equal("shinra:1:1", membership[:process].id)
        assert_equal("c4ca4238a0b9_0", membership[:subscription_group].id)
      end
    end

    context "when the consumers did not join their groups yet" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:consumer_groups].each_value do |cg|
          cg[:subscription_groups].each_value { |sg| sg[:member_id] = "" }
        end
        report
      end

      it { assert_empty(mapping) }
    end

    context "when the processes run a version that does not report member ids" do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:consumer_groups].each_value do |cg|
          cg[:subscription_groups].each_value { |sg| sg.delete(:member_id) }
        end
        report
      end

      it { assert_empty(mapping) }
    end

    context "when there are no active processes" do
      before { state[:processes][:"shinra:1:1"][:offset] = 1_000 }

      it { assert_empty(mapping) }
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
