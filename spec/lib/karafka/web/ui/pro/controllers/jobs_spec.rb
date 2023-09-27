# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe '#index' do
    context 'when needed topics are missing' do
      before do
        topics_config.consumers.states = SecureRandom.uuid
        topics_config.consumers.metrics = SecureRandom.uuid
        topics_config.consumers.reports = SecureRandom.uuid
        topics_config.errors = SecureRandom.uuid

        get 'jobs'
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when needed topics are present' do
      before { get 'jobs' }

      it do
        expect(response).to be_ok
        expect(body).to include('2023-08-01T09:47:51')
        expect(body).to include('ActiveJob::Consumer')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
      end
    end

    context 'when there are more jobs than fits on a single page' do
      before do
        topics_config.consumers.states = states_topic
        topics_config.consumers.reports = reports_topic

        data = Fixtures.json('consumers_state')
        base_report = Fixtures.json('consumer_report')

        100.times do |i|
          name = "shinra:#{i}:#{i}".to_sym

          data[:processes][name] = {
            dispatched_at: 2_690_818_669.526_218,
            offset: i
          }

          report = base_report.dup
          report[:process][:name] = name

          produce(reports_topic, report.to_json, key: name)
        end

        produce(states_topic, data.to_json)
      end

      context 'when visiting first page' do
        before { get 'jobs' }

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
          expect(body.scan('shinra:').size).to eq(25)
        end
      end

      context 'when visiting higher page' do
        before { get 'jobs?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include('shinra:32:32')
          expect(body).to include('shinra:34:34')
          expect(body).to include('shinra:35:35')
          expect(body).to include('shinra:35:35')
          expect(body.scan('shinra:').size).to eq(25)
        end
      end

      context 'when visiting page beyond available' do
        before { get 'jobs?page=100' }

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
