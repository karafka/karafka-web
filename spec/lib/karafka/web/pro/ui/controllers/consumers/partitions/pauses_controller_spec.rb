# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }
  let(:process_id) { 'shinra:1:1' }
  let(:subscription_group_id) { 'c4ca4238a0b9_0' }
  let(:topic_name) { 'default' }
  let(:partition_id) { 0 }
  let(:commands_topic) { create_topic }
  let(:lrj_warn1) { 'Manual pause/resume operations are not supported' }
  let(:lrj_warn2) { 'Cannot Manage Long-Running Job Partitions Pausing' }
  let(:cannot_perform) { 'This Operation Cannot Be Performed' }
  let(:not_active) { 'Consumer pauses can only be managed using Web UI when' }
  let(:form) { '<form' }
  let(:adjustment) { 'Pause Adjustment' }

  before do
    topics_config.consumers.states = states_topic
    topics_config.consumers.reports = reports_topic
    topics_config.consumers.commands = commands_topic

    produce(states_topic, Fixtures.consumers_states_file)
    produce(reports_topic, Fixtures.consumers_reports_file)
  end

  describe '#new' do
    let(:new_path) do
      [
        'consumers',
        process_id,
        'partitions',
        subscription_group_id,
        topic_name,
        partition_id,
        'pause',
        'new'
      ].join('/')
    end

    before { get(new_path) }

    context 'when the process exists and is running' do
      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(process_id)
        expect(body).to include(subscription_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include('Pause Duration:')
        expect(body).to include('Safety Check:')
        expect(body).to include(form)
        expect(body).to include(adjustment)
        expect(body).not_to include(lrj_warn1)
        expect(body).not_to include(lrj_warn2)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when the process exists, is running but topic is lrj' do
      before do
        topic = Karafka::App.routes.first.topics.to_a.first
        allow(Karafka::App.routes).to receive_messages(flat_map: Karafka::App.routes, find: topic)
        allow(topic).to receive(:long_running_job?).and_return(true)

        get(new_path)
      end

      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(process_id)
        expect(body).to include(subscription_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include(lrj_warn1)
        expect(body).to include(lrj_warn2)
        expect(body).to include(adjustment)
        expect(body).not_to include('Pause Duration:')
        expect(body).not_to include('Safety Check:')
        expect(body).not_to include(form)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when process does not exist' do
      let(:process_id) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when subscription_group is not correct' do
      let(:subscription_group_id) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when topic is not correct' do
      let(:topic_name) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when partition is not assigned to this process' do
      let(:partition_id) { 100 }

      it { expect(status).to eq(404) }
    end

    context 'when process exists but is not running' do
      before do
        report = Fixtures.consumers_reports_json
        report[:process][:status] = 'stopped'
        produce(reports_topic, report.to_json)

        get(new_path)
      end

      it 'expect to show not running error message' do
        expect(response).to be_ok
        expect(body).to include(cannot_perform)
        expect(body).to include(not_active)
        expect(body).not_to include(form)
      end
    end
  end

  describe '#create' do
    pending 'wip'
  end

  describe '#edit' do
    pending 'wip'
  end

  describe '#delete' do
    pending 'wip'
  end
end
