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
  let(:form) { '<form' }

  before do
    topics_config.consumers.states = states_topic
    topics_config.consumers.reports = reports_topic
    topics_config.consumers.commands = commands_topic

    produce(states_topic, Fixtures.consumers_states_file)
    produce(reports_topic, Fixtures.consumers_reports_file)
  end

  describe '#edit' do
    let(:edit_path) do
      [
        'consumers',
        process_id,
        'partitions',
        subscription_group_id,
        topic_name,
        partition_id,
        'offset',
        'edit'
      ].join('/')
    end

    before { get(edit_path) }

    context 'when the process exists and is running' do
      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(process_id)
        expect(body).to include(subscription_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include('New Offset:')
        expect(body).to include('Prevent Overtaking:')
        expect(body).to include('Resume Immediately:')
        expect(body).to include('checkbox')
        expect(body).to include('Adjust Offset')
        expect(body).to include('Consumers')
        expect(body).to include(form)
        expect(body).to include('Offsets')
        expect(body).to include('Edit')
        expect(body).to include('High Offset:')
        expect(body).to include('Low Offset:')
        expect(body).to include('EOF Offset:')
        expect(body).to include('Committed Offset:')
        expect(body).to include('Stored Offset:')
        expect(body).to include('Lag:')
        expect(body).to include('Running Consumer Process Operation')
        expect(body).to include('Takes effect during the next poll operation')
        expect(body).to include('May affect message processing')
        expect(body).not_to include('This Operation Cannot Be Performed')
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

        get(edit_path)
      end

      it 'expect to show not running error message' do
        expect(response).to be_ok
        expect(body).to include('This Operation Cannot Be Performed')
        expect(body).to include('Consumer offsets can only be modified using Web UI when the')
        expect(body).not_to include(form)
      end
    end
  end

  describe '#update' do
    let(:offset) { 100 }
    let(:prevent_overtaking) { 'no' }
    let(:force_resume) { 'on' }
    let(:post_path) do
      [
        'consumers',
        process_id,
        'partitions',
        subscription_group_id,
        topic_name,
        partition_id,
        'offset'
      ].join('/')
    end

    before do
      put(
        post_path,
        offset: offset,
        prevent_overtaking: prevent_overtaking,
        force_resume: force_resume
      )
    end

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq('/')
      expect(flash[:success]).to include("Initiated offset adjustment to #{offset}")
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first

      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.1.0')
      expect(message.payload[:type]).to eq('request')
      expect(message.payload[:dispatched_at]).not_to be_nil

      command = message.payload.fetch(:command)

      expect(command[:subscription_group_id]).to eq(subscription_group_id)
      expect(command[:consumer_group_id]).to eq('example_app6_app')
      expect(command[:topic]).to eq(topic_name)
      expect(command[:partition_id]).to eq(0)
      expect(command[:offset]).to eq(offset)
      expect(command[:prevent_overtaking]).to be(false)
      expect(command[:force_resume]).to be(true)
      expect(command[:name]).to eq('partitions.seek')
    end
  end
end
