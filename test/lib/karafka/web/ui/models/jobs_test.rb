# frozen_string_literal: true

describe_current do
  let(:jobs) { process.jobs }

  let(:process) { Karafka::Web::Ui::Models::Process.find(state, "shinra:1:1") }
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
    produce(reports_topic, report.to_json)
  end

  it "expect to operate correctly" do
    assert_equal(1, jobs.size)
  end

  describe "#running" do
    it { assert_equal(1, jobs.running.size) }
  end

  describe "#pending" do
    it { assert_equal(0, jobs.pending.size) }
  end

  describe "#select" do
    it "expect to return selection enclosed in jobs collection" do
      result = jobs.select(&:nil?)
      assert_kind_of(jobs.class, result)
    end
  end
end
