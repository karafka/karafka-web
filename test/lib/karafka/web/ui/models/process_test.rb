# frozen_string_literal: true

describe_current do
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
    produce(reports_topic, report.to_json)
  end

  describe ".find" do
    let(:lookup) { described_class.find(state, process_id) }

    context "when process with given id does not exist in the state" do
      let(:process_id) { SecureRandom.uuid }

      it { assert_raises(Karafka::Web::Errors::Ui::NotFoundError) { lookup } }
    end

    context "when process exists" do
      let(:process_id) { "shinra:1:1" }

      it { assert_kind_of(described_class, lookup) }
    end
  end

  describe "process attributes" do
    let(:process) { described_class.find(state, "shinra:1:1") }

    it "expect to have valid attributes configured" do
      assert_equal("shinra:1:1", process.id)
      assert_equal(2, process.consumer_groups.size)
      cgs = %w[example_app6_app example_app6_karafka_web]
      assert_equal(cgs, process.consumer_groups.map(&:id))
      assert_equal(1, process.jobs.size)
      assert_equal(1_690_883_271.5_342_352, process.jobs.first.updated_at)
      assert_equal(213_731_273, process.lag_stored)
      assert_equal(13, process.lag)
      assert_equal(3, process.subscribed_partitions_count)
      assert_equal(true, process.subscribed?)
    end
  end

  describe "#schema_compatible?" do
    let(:process) { described_class.find(state, "shinra:1:1") }

    context "when schema matches the one in memory" do
      it { assert_equal(true, process.schema_compatible?) }
    end

    context "when schema is newer than the one in memory" do
      before { process[:schema_version] = "#{process[:schema_version]}1" }

      it { assert_equal(false, process.schema_compatible?) }
    end

    context "when schema is older than the one in memory" do
      before { process[:schema_version] = "0.1" }

      it { assert_equal(false, process.schema_compatible?) }
    end
  end
end
