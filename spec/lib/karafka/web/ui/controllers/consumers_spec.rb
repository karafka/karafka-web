# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:no_processes) { 'There are no Karafka consumer processes' }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  context 'when the state data is missing' do
    before do
      topics_config.consumers.states = states_topic

      get 'consumers'
    end

    it do
      expect(response).not_to be_ok
      expect(status).to eq(404)
    end
  end

  context 'when there are no active consumers' do
    before do
      topics_config.consumers.reports = states_topic

      get 'consumers'
    end

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).not_to include(pagination)
      expect(body).to include(no_processes)
    end
  end

  context 'when there are active consumers' do
    before { get 'consumers' }

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).not_to include(no_processes)
      expect(body).not_to include(pagination)
      expect(body).to include('246 MB')
      expect(body).to include('shinra:1:1')
      expect(body).to include('/consumers/1/subscriptions')
      expect(body).to include('2690818651.82293')
    end
  end

  context 'when there are active consumers reported in a transactional fashion' do
    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.reports = reports_topic

      produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
      produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

      get 'consumers'
    end

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).not_to include(no_processes)
      expect(body).not_to include(pagination)
      expect(body).to include('246 MB')
      expect(body).to include('shinra:1:1')
      expect(body).to include('/consumers/1/subscriptions')
      expect(body).to include('2690818651.82293')
    end
  end

  context 'when there are more consumers that we fit in a single page' do
    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.reports = reports_topic

      data = Fixtures.consumers_states_json(symbolize_names: false)
      base_report = Fixtures.consumers_reports_json(symbolize_names: false)

      100.times do |i|
        name = "shinra:#{i}:#{i}"

        data['processes'][name] = {
          dispatched_at: 2_690_818_669.526_218,
          offset: i
        }

        report = base_report.dup
        report['process']['name'] = name

        produce(reports_topic, report.to_json, key: name)
      end

      produce(states_topic, data.to_json)
    end

    context 'when we visit first page' do
      before { get 'consumers' }

      it do
        expect(response).to be_ok
        expect(body).to include(pagination)
        expect(body).to include(support_message)
        expect(body).to include('shinra:0:0')
        expect(body).to include('shinra:1:1')
        expect(body).to include('shinra:11:11')
        expect(body).to include('shinra:12:12')
        expect(body.scan('shinra:').size).to eq(25)
      end
    end

    context 'when we visit second page' do
      before { get 'consumers?page=2' }

      it do
        expect(response).to be_ok
        expect(body).to include(pagination)
        expect(body).to include(support_message)
        expect(body).to include('shinra:32:32')
        expect(body).to include('shinra:34:34')
        expect(body).to include('shinra:35:35')
        expect(body).to include('shinra:35:35')
        expect(body.scan('shinra:').size).to eq(25)
      end
    end

    context 'when we go beyond available pages' do
      before { get 'consumers?page=100' }

      it do
        expect(response).to be_ok
        expect(body).to include(pagination)
        expect(body).to include(support_message)
        expect(body.scan('shinra:').size).to eq(0)
        expect(body).to include(no_meaningful_results)
      end
    end
  end
end
