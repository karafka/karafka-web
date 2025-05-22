# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe 'jobs/ path redirect' do
    context 'when visiting the jobs/ path without type indicator' do
      before { get 'jobs' }

      it 'expect to redirect to running jobs page' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include('jobs/running')
      end
    end
  end

  describe '#running' do
    context 'when needed topics are missing' do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get 'jobs/running'
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when needed topics are present' do
      before { get 'jobs/running' }

      it do
        expect(response).to be_ok
        expect(body).to include('2023-08-01T09:47:51')
        expect(body).to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
      end
    end

    context 'when we have only jobs different than running' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['status'] = 'pending'

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get 'jobs/running'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('There are no running jobs at the moment')
        expect(body).not_to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
      end
    end

    context 'when there are more jobs than fits on a single page' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        100.times do |i|
          id = "shinra:#{i}:#{i}"

          data['processes'][id] = {
            dispatched_at: 2_690_818_669.526_218,
            offset: i
          }

          report = base_report.dup
          report['process']['id'] = id

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, data.to_json)
      end

      context 'when visiting first page' do
        before { get 'jobs/running' }

        it do
          expect(response).to be_ok
          expect(body).to include('2023-08-01T09:47:51')
          expect(body.scan('ActiveJob::Consumer').size).to eq(25)
          expect(body).not_to include(support_message)
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(50)
        end

        context 'when sorted' do
          before { get 'jobs/running?sort=consumer+desc' }

          it { expect(response).to be_ok }
        end
      end

      context 'when visiting page with data published in a transactional fashion' do
        before do
          topics_config.consumers.states.name = states_topic
          topics_config.consumers.reports.name = reports_topic

          produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
          produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

          get 'jobs/running'
        end

        it do
          expect(response).to be_ok
          expect(body).to include('2023-08-01T09:47:51')
          expect(body.scan('ActiveJob::Consumer').size).to eq(25)
          expect(body).not_to include(support_message)
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(50)
        end
      end

      context 'when visiting higher page' do
        before { get 'jobs/running?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include('shinra:32:32')
          expect(body).to include('shinra:34:34')
          expect(body).to include('shinra:35:35')
          expect(body).to include('shinra:35:35')
          expect(body.scan('shinra:').size).to eq(50)
        end
      end

      context 'when visiting page beyond available' do
        before { get 'jobs/running?page=100' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body.scan('shinra:').size).to eq(0)
          expect(body).to include(no_meaningful_results)
        end
      end
    end

    context 'when we visit tick jobs' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['type'] = 'tick'

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get 'jobs/running'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('2023-08-01T09:47:51')
        expect(body).to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('#tick')
        expect(body).not_to include('#consume')
        expect(body).not_to include(pagination)
      end
    end

    context 'when we visit shutdown jobs' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['type'] = 'shutdown'

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get 'jobs/running'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('2023-08-01T09:47:51')
        expect(body).to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('#shutdown')
        expect(body).not_to include('#consume')
        expect(body).not_to include(pagination)
      end
    end
  end

  describe '#pending' do
    context 'when needed topics are missing' do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get 'jobs/pending'
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when needed topics are present with data' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['status'] = 'pending'

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get 'jobs/pending'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('2023-08-01T09:47:51')
        expect(body).to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
      end
    end

    context 'when we have only jobs different than pending' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['jobs'][0]['status'] = 'running'

        produce(reports_topic, report.to_json)
        produce(states_topic, data.to_json)

        get 'jobs/pending'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('There are no pending jobs at the moment')
        expect(body).not_to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
      end
    end

    context 'when there are more jobs than fits on a single page' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        data = Fixtures.consumers_states_json(symbolize_names: false)
        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        base_report['jobs'].first['status'] = 'pending'

        100.times do |i|
          id = "shinra:#{i}:#{i}"

          data['processes'][id] = {
            dispatched_at: 2_690_818_669.526_218,
            offset: i
          }

          report = base_report.dup
          report['process']['id'] = id

          produce(reports_topic, report.to_json, key: id)
        end

        produce(states_topic, data.to_json)
      end

      context 'when visiting first page' do
        before { get 'jobs/pending' }

        it do
          expect(response).to be_ok
          expect(body).to include('2023-08-01T09:47:51')
          expect(body.scan('ActiveJob::Consumer').size).to eq(25)
          expect(body).not_to include(support_message)
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(50)
        end
      end

      context 'when visiting page with data published in a transactional fashion' do
        before do
          topics_config.consumers.states.name = states_topic
          topics_config.consumers.reports.name = reports_topic

          produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
          produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

          get 'jobs/pending'
        end

        it do
          expect(response).to be_ok
          expect(body).to include('2023-08-01T09:47:51')
          expect(body.scan('ActiveJob::Consumer').size).to eq(25)
          expect(body).not_to include(support_message)
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(50)
        end
      end

      context 'when visiting higher page' do
        before { get 'jobs/pending?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include('shinra:32:32')
          expect(body).to include('shinra:34:34')
          expect(body).to include('shinra:35:35')
          expect(body).to include('shinra:35:35')
          expect(body.scan('shinra:').size).to eq(50)
        end
      end

      context 'when visiting page beyond available' do
        before { get 'jobs/pending?page=100' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body.scan('shinra:').size).to eq(0)
          expect(body).to include(no_meaningful_results)
        end
      end
    end
  end
end
