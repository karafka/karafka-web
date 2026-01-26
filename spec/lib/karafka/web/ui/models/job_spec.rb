# frozen_string_literal: true

RSpec.describe_current do
  subject(:job) { process.jobs.first }

  let(:process) { Karafka::Web::Ui::Models::Process.find(state, "shinra:1:1") }
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
    produce(reports_topic, report.to_json)
  end

  it "expect to have proper attributes" do
    expect(job.updated_at).to eq(1_690_883_271.5_342_352)
    expect(job.topic).to eq("default")
    expect(job.partition).to eq(0)
    expect(job.first_offset).to eq(327_359)
    expect(job.last_offset).to eq(327_361)
    expect(job.processing_lag).to eq(0)
    expect(job.consumption_lag).to eq(250)
    expect(job.committed_offset).to eq(327_358)
    expect(job.messages).to eq(3)
    expect(job.consumer).to eq("Karafka::Pro::ActiveJob::Consumer")
    expect(job.consumer_group).to eq("example_app6_app")
    expect(job.type).to eq("consume")
    expect(job.tags).to eq(%w[active_job VisitorsJob])
  end
end
