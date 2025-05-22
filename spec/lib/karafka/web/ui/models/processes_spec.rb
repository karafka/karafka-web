# frozen_string_literal: true

RSpec.describe_current do
  let(:state) { Fixtures.consumers_states_json }
  let(:report) { Fixtures.consumers_reports_json }
  let(:reports_topic) { create_topic }

  before do
    Karafka::Web.config.topics.consumers.reports.name = reports_topic
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
        report = Fixtures.consumers_reports_json
        report[:dispatched_at] = 1_690_883_271
        report
      end

      it { expect(processes).to be_empty }
    end

    context 'when requested processes are active' do
      it { expect(processes).not_to be_empty }
    end

    context 'when there is a requested process with incompatible schema' do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:schema_version] = '0.1'
        report
      end

      it 'expect not to include them' do
        expect(processes).to be_empty
      end
    end
  end

  describe '#all' do
    subject(:processes) { described_class.all(state) }

    context 'when the requested processes from states do not exist' do
      before { state[:processes][:'shinra:1:1'][:offset] = 1_000 }

      it { expect(processes).to be_empty }
    end

    context 'when requested processes are too old' do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:dispatched_at] = 1_690_883_271
        report
      end

      it { expect(processes).to be_empty }
    end

    context 'when requested processes are alive' do
      it { expect(processes).not_to be_empty }
    end

    context 'when there is a requested process with incompatible schema' do
      let(:report) do
        report = Fixtures.consumers_reports_json
        report[:schema_version] = '0.1'
        report
      end

      it 'expect to include them' do
        expect(processes).not_to be_empty
      end
    end
  end
end
