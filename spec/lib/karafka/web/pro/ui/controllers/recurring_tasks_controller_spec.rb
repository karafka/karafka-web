# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:schedules_topic) { create_topic }
  let(:logs_topic) { create_topic }
  let(:not_operable) { 'Recurring Tasks Data Unavailable' }
  let(:no_logs) { 'There are no available logs.' }

  before do
    topics = Karafka::App.config.recurring_tasks.topics
    topics.schedules = schedules_topic
    topics.logs = logs_topic

    draw_routes do
      recurring_tasks(true)
    end
  end

  describe '#schedule' do
    context 'when schedules topic does not exist' do
      let(:schedules_topic) { SecureRandom.uuid }
      let(:logs_topic) { SecureRandom.uuid }

      before { get 'recurring_tasks/schedule' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(not_operable)
      end
    end

    context 'when schedules topic exists but there is no data' do
      before { get 'recurring_tasks/schedule' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(not_operable)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('Schedule 1.0.0')
      end
    end

    context 'when schedules topic exists but there are only commands recently and no state' do
      before do
        produce_many(schedules_topic, Array.new(50, ''))

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(not_operable)
        expect(body).not_to include('Schedule 1.0.0')
      end
    end

    context 'when state is the most recent message and its of an empty cron' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('empty'),
          key: 'state:schedule'
        )

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(not_operable)
        expect(body).to include('Schedule 1.0.0')
      end
    end

    context 'when state is behind other messages but reachable' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('empty'),
          key: 'state:schedule'
        )

        produce_many(schedules_topic, Array.new(15, ''))

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(not_operable)
        expect(body).to include('Schedule 1.0.0')
      end
    end

    context 'when state is behind other messages and not reachable' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('empty'),
          key: 'state:schedule'
        )

        produce_many(schedules_topic, Array.new(50, ''))

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(not_operable)
        expect(body).not_to include('Schedule 1.0.0')
      end
    end

    context 'when state has only disabled tasks that were never running' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('only_disabled_never_running'),
          key: 'state:schedule'
        )

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Never')
        expect(body).to include('* * * * *')
        expect(body).to include('*/2 * * *')
        expect(body).to include('Disabled')
        expect(body).to include('status-row-warning text-muted')
        expect(body).to include('btn btn-warning btn-sm btn-disabled')
        expect(body).to include('Schedule 1.0.1')
        expect(body).not_to include(not_operable)
        expect(body).not_to include('<time class="ltr" dir="ltr"')
      end
    end

    context 'when state has only disabled tasks that were running' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('only_disabled_running'),
          key: 'state:schedule'
        )

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Never')
        expect(body).to include('* * * * *')
        expect(body).to include('*/2 * * *')
        expect(body).to include('Disabled')
        expect(body).to include('<time class="ltr" dir="ltr"')
        expect(body).to include('status-row-warning text-muted')
        expect(body).to include('btn btn-warning btn-sm btn-disabled')
        expect(body).to include('Schedule 1.0.1')
        expect(body).not_to include(not_operable)
      end
    end

    context 'when state has only enabled tasks that were running' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('only_enabled'),
          key: 'state:schedule'
        )

        get 'recurring_tasks/schedule'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('* * * * *')
        expect(body).to include('*/2 * * *')
        expect(body).to include('Enabled')
        expect(body).to include('<time class="ltr" dir="ltr"')
        expect(body).to include('Schedule 1.0.1')
        expect(body).not_to include('btn btn-warning btn-sm btn-disabled')
        expect(body).not_to include('status-row-warning text-muted')
        expect(body).not_to include('Never')
        expect(body).not_to include(not_operable)
      end
    end

    context 'when sorting' do
      before do
        produce(
          schedules_topic,
          Fixtures.recurring_tasks_schedules_msg('only_enabled'),
          key: 'state:schedule'
        )

        get 'recurring_tasks/schedule?sort=enabled+desc'
      end

      it 'expect not to crash' do
        expect(response).to be_ok
      end
    end
  end

  describe '#logs' do
    context 'when logs topic does not exist' do
      let(:schedules_topic) { SecureRandom.uuid }
      let(:logs_topic) { SecureRandom.uuid }

      before { get 'recurring_tasks/logs' }

      it do
        expect(response.status).to eq(404)
      end
    end

    context 'when there are no logs' do
      before { get 'recurring_tasks/logs' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_logs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are few successful logs only' do
      before do
        log = Fixtures.recurring_tasks_logs_msg('success')
        produce_many(logs_topic, Array.new(10, log))

        get 'recurring_tasks/logs'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('test1')
        expect(body).to include('1.0.1')
        expect(body).to include('<span class="badge  badge-success">Success</span>')
        expect(body).not_to include(no_logs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are few failed logs only' do
      before do
        log = Fixtures.recurring_tasks_logs_msg('failed')
        produce_many(logs_topic, Array.new(10, log))

        get 'recurring_tasks/logs'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('test2')
        expect(body).to include('1.0.1')
        expect(body).to include('<span class="badge  badge-error">Error</span>')
        expect(body).not_to include(no_logs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are many mixed logs on many pages' do
      before do
        failed = Fixtures.recurring_tasks_logs_msg('failed')
        success = Fixtures.recurring_tasks_logs_msg('success')
        logs = [failed, success] * 25
        produce_many(logs_topic, logs)

        get 'recurring_tasks/logs'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('test1')
        expect(body).to include('test2')
        expect(body).to include('1.0.1')
        expect(body).to include('<span class="badge  badge-error">Error</span>')
        expect(body).to include(pagination)
        expect(body).not_to include(no_logs)
        expect(body).not_to include(support_message)
      end
    end

    context 'when we fetch second offset-based page' do
      before do
        failed = Fixtures.recurring_tasks_logs_msg('failed')
        success = Fixtures.recurring_tasks_logs_msg('success')
        logs = [failed, success] * 25
        produce_many(logs_topic, logs)

        get 'recurring_tasks/logs?offset=25'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('test1')
        expect(body).to include('test2')
        expect(body).to include('1.0.1')
        expect(body).to include('<span class="badge  badge-error">Error</span>')
        expect(body).to include(pagination)
        expect(body).not_to include(no_logs)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe '#trigger_all' do
    before { post 'recurring_tasks/trigger_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first
      expect(message.key).to eq('command:trigger:*')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:command][:name]).to eq('trigger')
      expect(message.payload[:task][:id]).to eq('*')
    end
  end

  describe '#disable_all' do
    before { post 'recurring_tasks/disable_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first
      expect(message.key).to eq('command:disable:*')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:command][:name]).to eq('disable')
      expect(message.payload[:task][:id]).to eq('*')
    end
  end

  describe '#enable_all' do
    before { post 'recurring_tasks/enable_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first
      expect(message.key).to eq('command:enable:*')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:command][:name]).to eq('enable')
      expect(message.payload[:task][:id]).to eq('*')
    end
  end

  describe '#enable' do
    before { post 'recurring_tasks/task1/enable' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first
      expect(message.key).to eq('command:enable:task1')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:command][:name]).to eq('enable')
      expect(message.payload[:task][:id]).to eq('task1')
    end
  end

  describe '#disable' do
    before { post 'recurring_tasks/task1/disable' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first
      expect(message.key).to eq('command:disable:task1')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:command][:name]).to eq('disable')
      expect(message.payload[:task][:id]).to eq('task1')
    end
  end

  describe '#trigger' do
    before { post 'recurring_tasks/task1/trigger' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(schedules_topic, 0, 1, -1).first
      expect(message.key).to eq('command:trigger:task1')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:command][:name]).to eq('trigger')
      expect(message.payload[:task][:id]).to eq('task1')
    end
  end
end
