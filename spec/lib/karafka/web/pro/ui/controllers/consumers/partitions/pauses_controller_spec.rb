# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }
  let(:consumer_group_id) { 'example_app6_app' }
  let(:topic_name) { 'default' }
  let(:partition_id) { 0 }
  let(:commands_topic) { create_topic }
  let(:lrj_warn1) { 'Manual pause/resume operations are not supported' }
  let(:lrj_warn2) { 'Cannot Manage Long-Running Job Partitions Pausing' }
  let(:cannot_perform) { 'This Operation Cannot Be Performed' }
  let(:not_active) { 'Consumer pauses can only be managed using Web UI when' }
  let(:not_paused) { 'Pause settings can only be configured for partitions' }
  let(:form) { '<form' }
  let(:card_detail) { 'card-detail-container' }

  before do
    topics_config.consumers.states.name = states_topic
    topics_config.consumers.reports.name = reports_topic
    topics_config.consumers.commands.name = commands_topic

    produce(states_topic, Fixtures.consumers_states_file)
    produce(reports_topic, Fixtures.consumers_reports_file)
  end

  describe '#new' do
    let(:new_path) do
      [
        'consumers',
        'partitions',
        consumer_group_id,
        topic_name,
        partition_id,
        'pause',
        'new'
      ].join('/')
    end

    before { get(new_path) }

    context 'when a process exists and is running' do
      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(consumer_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include('Pause Duration:')
        expect(body).to include('Safety Check:')
        expect(body).to include(form)
        expect(body).to include(card_detail)
        expect(body).not_to include(lrj_warn1)
        expect(body).not_to include(lrj_warn2)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when a process exists, is running but topic is lrj' do
      before do
        # Capture let values for use inside routes.draw block
        cg_id = consumer_group_id
        t_name = topic_name

        # Add routing for the consumer group and topic so LRJ detection works
        Karafka::App.routes.draw do
          consumer_group cg_id do
            topic t_name do
              consumer Class.new(Karafka::BaseConsumer)
              long_running_job true
            end
          end
        end

        get(new_path)
      end

      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(consumer_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include(lrj_warn1)
        expect(body).to include(lrj_warn2)
        expect(body).not_to include('Pause Duration:')
        expect(body).not_to include('Safety Check:')
        expect(body).not_to include(form)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when consumer group does not exist' do
      let(:consumer_group_id) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when topic is not correct' do
      let(:topic_name) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when partition does not exist' do
      let(:partition_id) { 100 }

      it { expect(status).to eq(404) }
    end

    context 'when no process is running' do
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
    let(:duration) { 60 }
    let(:prevent_override) { 'on' }
    let(:post_path) do
      [
        'consumers',
        'partitions',
        consumer_group_id,
        topic_name,
        partition_id,
        'pause'
      ].join('/')
    end

    before do
      post(
        post_path,
        duration: duration,
        prevent_override: prevent_override
      )
    end

    context 'when a process exists and is running' do
      it 'expect to redirect with success message' do
        expect(response.status).to eq(302)
        expect(flash[:success]).to include(
          "Initiated pause for partition #{topic_name}##{partition_id}"
        )
      end

      it 'expect to create pause command with correct parameters' do
        sleep(1)
        message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first

        # Commands are broadcast to all processes, so no key
        expect(message.key).to be_nil
        expect(message.payload[:schema_version]).to eq('1.2.0')
        expect(message.payload[:type]).to eq('request')
        expect(message.payload[:id]).to match(/\A[0-9a-f-]{36}\z/)
        expect(message.payload[:dispatched_at]).not_to be_nil

        command = message.payload.fetch(:command)

        expect(command[:consumer_group_id]).to eq(consumer_group_id)
        expect(command[:topic]).to eq(topic_name)
        expect(command[:partition_id]).to eq(partition_id)
        expect(command[:duration]).to eq(duration * 1_000)
        expect(command[:prevent_override]).to be(true)
        expect(command[:name]).to eq('partitions.pause')

        matchers = message.payload.fetch(:matchers)
        expect(matchers[:consumer_group_id]).to eq(consumer_group_id)
        expect(matchers[:topic]).to eq(topic_name)
        expect(matchers[:partition_id]).to eq(partition_id)
      end
    end

    context 'when consumer group does not exist' do
      let(:consumer_group_id) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when topic is not correct' do
      let(:topic_name) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when partition does not exist' do
      let(:partition_id) { 100 }

      it { expect(status).to eq(404) }
    end
  end

  describe '#edit' do
    let(:edit_path) do
      [
        'consumers',
        'partitions',
        consumer_group_id,
        topic_name,
        partition_id,
        'pause',
        'edit'
      ].join('/')
    end

    before { get(edit_path) }

    context 'when a process exists and is running and partition is not paused' do
      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(consumer_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include(not_paused)
        expect(body).not_to include(form)
        expect(body).not_to include('Reset Counter:')
        expect(body).not_to include('Resume Processing')
        expect(body).not_to include(lrj_warn1)
        expect(body).not_to include(lrj_warn2)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when a process exists and is running and partition is paused' do
      before do
        report = Fixtures.consumers_reports_json
        sg = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        sg[:topics][:default][:partitions][:'0'][:poll_state] = 'paused'

        produce(reports_topic, report.to_json)

        get(edit_path)
      end

      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(consumer_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include('Reset Counter:')
        expect(body).to include('Resume Processing')
        expect(body).to include(form)
        expect(body).not_to include(not_paused)
        expect(body).not_to include(lrj_warn1)
        expect(body).not_to include(lrj_warn2)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when a process exists, is running but topic is lrj' do
      before do
        # Capture let values for use inside routes.draw block
        cg_id = consumer_group_id
        t_name = topic_name

        # Add routing for the consumer group and topic so LRJ detection works
        Karafka::App.routes.draw do
          consumer_group cg_id do
            topic t_name do
              consumer Class.new(Karafka::BaseConsumer)
              long_running_job true
            end
          end
        end

        get(edit_path)
      end

      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(consumer_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(partition_id.to_s)
        expect(body).to include(lrj_warn1)
        expect(body).to include(lrj_warn2)
        expect(body).not_to include(not_paused)
        expect(body).not_to include('Reset Counter:')
        expect(body).not_to include('Resume Processing')
        expect(body).not_to include(form)
        expect(body).not_to include(cannot_perform)
        expect(body).not_to include(not_active)
      end
    end

    context 'when consumer group does not exist' do
      let(:consumer_group_id) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when topic is not correct' do
      let(:topic_name) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when partition does not exist' do
      let(:partition_id) { 100 }

      it { expect(status).to eq(404) }
    end

    context 'when no process is running' do
      before do
        report = Fixtures.consumers_reports_json
        report[:process][:status] = 'stopped'
        produce(reports_topic, report.to_json)

        get(edit_path)
      end

      it 'expect to show not running error message' do
        expect(response).to be_ok
        expect(body).to include(cannot_perform)
        expect(body).to include(not_active)
        expect(body).not_to include(form)
      end
    end
  end

  describe '#delete' do
    let(:reset_attempts) { 'yes' }
    let(:delete_path) do
      [
        'consumers',
        'partitions',
        consumer_group_id,
        topic_name,
        partition_id,
        'pause'
      ].join('/')
    end

    before do
      delete(
        delete_path,
        reset_attempts: reset_attempts
      )
    end

    context 'when a process exists and is running' do
      it 'expect to redirect with success message' do
        expect(response.status).to eq(302)
        expect(flash[:success]).to include(
          "Initiated resume for partition #{topic_name}##{partition_id}"
        )
      end

      it 'expect to create resume command with correct parameters' do
        sleep(1)
        message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first

        # Commands are broadcast to all processes, so no key
        expect(message.key).to be_nil
        expect(message.payload[:schema_version]).to eq('1.2.0')
        expect(message.payload[:type]).to eq('request')
        expect(message.payload[:id]).to match(/\A[0-9a-f-]{36}\z/)
        expect(message.payload[:dispatched_at]).not_to be_nil

        command = message.payload.fetch(:command)

        expect(command[:consumer_group_id]).to eq(consumer_group_id)
        expect(command[:topic]).to eq(topic_name)
        expect(command[:partition_id]).to eq(partition_id)
        expect(command[:reset_attempts]).to be(true)
        expect(command[:name]).to eq('partitions.resume')

        matchers = message.payload.fetch(:matchers)
        expect(matchers[:consumer_group_id]).to eq(consumer_group_id)
        expect(matchers[:topic]).to eq(topic_name)
        expect(matchers[:partition_id]).to eq(partition_id)
      end
    end

    context 'when consumer group does not exist' do
      let(:consumer_group_id) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when topic is not correct' do
      let(:topic_name) { 'not-existing' }

      it { expect(status).to eq(404) }
    end

    context 'when partition does not exist' do
      let(:partition_id) { 100 }

      it { expect(status).to eq(404) }
    end
  end
end
