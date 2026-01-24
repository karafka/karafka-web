# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }
  let(:consumer_group_id) { 'example_app6_app' }
  let(:topic_name) { 'default' }
  let(:commands_topic) { create_topic }
  let(:lrj_warn1) { 'Manual pause/resume operations are not supported' }
  let(:lrj_warn2) { 'Cannot Manage Long-Running Job Partitions Pausing' }
  let(:cannot_perform) { 'This Operation Cannot Be Performed' }
  let(:not_active) { 'Topic pauses can only be managed using Web UI when' }
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
        'topics',
        consumer_group_id,
        topic_name,
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
        'topics',
        consumer_group_id,
        topic_name,
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
        expect(response.location).to eq('/')
        expected_message = "Initiated pause for all partitions of the #{topic_name}"
        expect(flash[:success]).to include(expected_message)
      end

      it 'expect to create pause command with correct parameters' do
        sleep(1)
        message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first

        # Broadcast commands don't need a key
        expect(message.key).to be_nil
        expect(message.payload[:schema_version]).to eq('1.2.0')
        expect(message.payload[:type]).to eq('request')
        expect(message.payload[:id]).to match(/\A[0-9a-f-]{36}\z/)
        expect(message.payload[:dispatched_at]).not_to be_nil

        # Matchers for filtering which processes handle this command
        matchers = message.payload.fetch(:matchers)
        expect(matchers[:consumer_group_id]).to eq(consumer_group_id)
        expect(matchers[:topic]).to eq(topic_name)

        command = message.payload.fetch(:command)

        expect(command[:consumer_group_id]).to eq(consumer_group_id)
        expect(command[:topic]).to eq(topic_name)
        expect(command[:duration]).to eq(duration * 1_000)
        expect(command[:prevent_override]).to be(true)
        expect(command[:name]).to eq('topics.pause')
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
  end

  describe '#edit' do
    let(:edit_path) do
      [
        'consumers',
        'topics',
        consumer_group_id,
        topic_name,
        'pause',
        'edit'
      ].join('/')
    end

    before { get(edit_path) }

    context 'when a process exists and is running' do
      it 'expect to include relevant details' do
        expect(response).to be_ok
        expect(body).to include(consumer_group_id)
        expect(body).to include(topic_name)
        expect(body).to include(card_detail)
        expect(body).to include('Reset Counter:')
        expect(body).to include('Resume All Paused Partitions')
        expect(body).to include(form)
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
        expect(body).to include(lrj_warn1)
        expect(body).to include(lrj_warn2)
        expect(body).not_to include('Reset Counter:')
        expect(body).not_to include('Resume All Paused Partitions')
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
        'topics',
        consumer_group_id,
        topic_name,
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
        expect(response.location).to eq('/')
        expected_message = "Initiated resume for all partitions of the #{topic_name}"
        expect(flash[:success]).to include(expected_message)
      end

      it 'expect to create resume command with correct parameters' do
        sleep(1)
        message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first

        # Broadcast commands don't need a key
        expect(message.key).to be_nil
        expect(message.payload[:schema_version]).to eq('1.2.0')
        expect(message.payload[:type]).to eq('request')
        expect(message.payload[:id]).to match(/\A[0-9a-f-]{36}\z/)
        expect(message.payload[:dispatched_at]).not_to be_nil

        # Matchers for filtering which processes handle this command
        matchers = message.payload.fetch(:matchers)
        expect(matchers[:consumer_group_id]).to eq(consumer_group_id)
        expect(matchers[:topic]).to eq(topic_name)

        command = message.payload.fetch(:command)

        expect(command[:consumer_group_id]).to eq(consumer_group_id)
        expect(command[:topic]).to eq(topic_name)
        expect(command[:reset_attempts]).to be(true)
        expect(command[:name]).to eq('topics.resume')
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
  end
end
