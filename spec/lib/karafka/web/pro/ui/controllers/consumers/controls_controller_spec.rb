# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:no_processes) { 'There Are No Karafka Consumer Processes' }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe '#index' do
    context 'when the state data is missing' do
      before do
        topics_config.consumers.states.name = states_topic

        get 'consumers/controls'
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there are no active consumers' do
      before do
        topics_config.consumers.reports.name = states_topic

        get 'consumers/controls'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_processes)
      end
    end

    context 'when there are active consumers' do
      before { get 'consumers/controls' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('running')
        expect(body).to include('ID')
        expect(body).to include('Performance')
        expect(body).to include('Quiet All')
        expect(body).to include('Stop All')
        expect(body).to include('Trace')
      end

      context 'when sorting' do
        before { get 'consumers/controls?sort=id+desc' }

        it { expect(response).to be_ok }
      end
    end

    context 'when there are active embedded consumers' do
      before do
        topics_config.consumers.reports.name = reports_topic

        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        10.times do |i|
          id = "shinra:#{i}:#{i}"

          report = base_report.dup
          report['process']['execution_mode'] = 'embedded'

          produce(reports_topic, report.to_json, key: id)
        end

        get 'consumers/controls'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('running')
        expect(body).to include('ID')
        expect(body).to include('Performance')
        expect(body).to include('Quiet All')
        expect(body).to include('Stop All')
        expect(body).to include('Trace')
        expect(body).to include('title="Supported only in standalone consumer processes"')
      end

      context 'when sorting' do
        before { get 'consumers/controls?sort=id+desc' }

        it { expect(response).to be_ok }
      end
    end

    context 'when there are active swarm consumers' do
      before do
        topics_config.consumers.reports.name = reports_topic

        base_report = Fixtures.consumers_reports_json(symbolize_names: false)

        10.times do |i|
          id = "shinra:#{i}:#{i}"

          report = base_report.dup
          report['process']['execution_mode'] = 'swarm'

          produce(reports_topic, report.to_json, key: id)
        end

        get 'consumers/controls'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('running')
        expect(body).to include('ID')
        expect(body).to include('Performance')
        expect(body).to include('Quiet All')
        expect(body).to include('Stop All')
        expect(body).to include('Trace')
        expect(body).to include('title="Supported only in standalone consumer processes"')
      end

      context 'when sorting' do
        before { get 'consumers/controls?sort=id+desc' }

        it { expect(response).to be_ok }
      end
    end

    context 'when there are active consumers reported in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'consumers/controls'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('running')
        expect(body).to include('ID')
        expect(body).to include('Performance')
        expect(body).to include('Quiet All')
        expect(body).to include('Stop All')
        expect(body).to include('Trace')
      end
    end

    context 'when there are more consumers that we fit in a single page' do
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

      context 'when we visit first page' do
        before { get 'consumers/controls' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(125)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we visit second page' do
        before { get 'consumers/controls?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include('shinra:32:32')
          expect(body).to include('shinra:34:34')
          expect(body).to include('shinra:35:35')
          expect(body).to include('shinra:35:35')
          expect(body.scan('shinra:').size).to eq(125)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we go beyond available pages' do
        before { get 'consumers/controls?page=100' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include(no_meaningful_results)
          expect(body.scan('shinra:').size).to eq(0)
          expect(body).not_to include(support_message)
        end
      end
    end
  end
end
