# frozen_string_literal: true

RSpec.describe_current do
  let(:state) { JSON.parse(fixtures_file('consumers_state.json'), symbolize_names: true) }
  let(:report) { JSON.parse(fixtures_file('consumer_report.json'), symbolize_names: true) }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports = reports_topic
    produce(reports_topic, report.to_json)
  end

  describe '#active' do
    subject(:processes) { described_class.active(state) }

    context 'when the requested processes from states do not exist' do
      before { state[:processes][:'shinra:1:1'][:offset] = 1_000 }

      it { expect(processes).to be_empty }
    end

    context 'when requested processes are too old' do
      let(:report) do
        report = JSON.parse(fixtures_file('consumer_report.json'), symbolize_names: true)
        report[:dispatched_at] = 1690883271
        report
      end

      it { expect(processes).to be_empty }
    end

    context 'when requested processes are active' do
      it { expect(processes).not_to be_empty }
    end
  end
end
