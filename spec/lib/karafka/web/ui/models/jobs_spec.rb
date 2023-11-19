# frozen_string_literal: true

RSpec.describe_current do
  subject(:jobs) { process.jobs }

  let(:process) { Karafka::Web::Ui::Models::Process.find(state, '1') }
  let(:state) { Fixtures.json('consumers_state') }
  let(:report) { Fixtures.json('consumer_report') }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports = reports_topic
    produce(reports_topic, report.to_json)
  end

  it 'expect to operate correctly' do
    expect(jobs.size).to eq(1)
  end

  describe '#running' do
    it { expect(jobs.running.size).to eq(1) }
  end

  describe '#pending' do
    it { expect(jobs.pending.size).to eq(0) }
  end

  describe '#select' do
    it 'expect to return selection enclosed in jobs collection' do
      result = jobs.select(&:nil?)
      expect(result).to be_a(jobs.class)
    end
  end
end
