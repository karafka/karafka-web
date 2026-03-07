# frozen_string_literal: true

describe_current do
  let(:job) { process.jobs.first }

  let(:process) { Karafka::Web::Ui::Models::Process.find(state, "shinra:1:1") }
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
    produce(reports_topic, report.to_json)
  end

  it "expect to have proper attributes" do
    assert_in_delta(1_690_883_271.5_342_352, job.updated_at)
    assert_equal("default", job.topic)
    assert_equal(0, job.partition)
    assert_equal(327_359, job.first_offset)
    assert_equal(327_361, job.last_offset)
    assert_equal(0, job.processing_lag)
    assert_equal(250, job.consumption_lag)
    assert_equal(327_358, job.committed_offset)
    assert_equal(3, job.messages)
    assert_equal("Karafka::Pro::ActiveJob::Consumer", job.consumer)
    assert_equal("example_app6_app", job.consumer_group)
    assert_equal("consume", job.type)
    assert_equal(%w[active_job VisitorsJob], job.tags)
  end
end
