# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:no_processes) { 'There Are No Karafka Consumer Processes' }
  let(:states_topic) { create_topic }
  let(:reports_topic) { create_topic }

  describe '#index' do
    context 'when we open a consumers root' do
      before { get 'consumers' }

      it 'expect to redirect to overview page' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include('consumers/overview')
      end
    end

    context 'when the state data is missing' do
      before do
        topics_config.consumers.states.name = states_topic

        get 'consumers/overview'
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there are no active consumers' do
      before do
        topics_config.consumers.reports.name = states_topic

        get 'consumers/overview'
      end

      it do
        expect(body).not_to include('Pro Feature')
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).to include(no_processes)
      end
    end

    context 'when commanding is disabled' do
      before do
        Karafka::Web.config.commanding.active = false

        get 'consumers/overview'
      end

      it do
        expect(response).to be_ok

        expect(body).to include('Commands')
        expect(body).to include('Controls')
        expect(body).not_to include('Pro Feature')
      end
    end

    context 'when commanding is enabled' do
      before do
        Karafka::Web.config.commanding.active = true

        get 'consumers/overview'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Controls')
        expect(body).to include('Commands')
      end
    end

    context 'when there are active consumers' do
      before { get 'consumers/overview' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include('246 MB')
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('2690818651.82293')
      end

      context 'when sorting' do
        before { get 'consumers/overview?sort=id+desc' }

        it { expect(response).to be_ok }
      end
    end

    context 'when there are active consumers with many partitions assigned' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        scope = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        base = scope[:topics][:default][:partitions]

        50.times { |i| base[i + 1] = base[:'0'].dup.merge(id: i + 1) }

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get 'consumers/overview'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('0-50')
        expect(body).to include('default-[0-50] (51 partitions total)')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include('246 MB')
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('2690818651.82293')
      end
    end

    context 'when there are active consumers reported in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'consumers/overview'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include('246 MB')
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('2690818651.82293')
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
        before { get 'consumers/overview' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(50)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we visit second page' do
        before { get 'consumers/overview?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include('shinra:32:32')
          expect(body).to include('shinra:34:34')
          expect(body).to include('shinra:35:35')
          expect(body).to include('shinra:35:35')
          expect(body.scan('shinra:').size).to eq(50)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we go beyond available pages' do
        before { get 'consumers/overview?page=100' }

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

  describe '#performance' do
    context 'when the state data is missing' do
      before do
        topics_config.consumers.states.name = states_topic

        get 'consumers/performance'
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there are no active consumers' do
      before do
        topics_config.consumers.reports.name = states_topic

        get 'consumers/performance'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_processes)
      end
    end

    context 'when commanding is enabled' do
      before do
        Karafka::Web.config.commanding.active = true

        get 'consumers/performance'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Controls')
        expect(body).to include('Commands')
      end
    end

    context 'when there are active consumers' do
      before { get 'consumers/performance' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('RSS')
        expect(body).to include('ID')
        expect(body).to include('Utilization')
        expect(body).to include('Threads')
        expect(body).to include('120 MB')
        expect(body).to include('5.6%')
      end

      context 'when sorting' do
        before { get 'consumers/performance?sort=id+desc' }

        it { expect(response).to be_ok }
      end
    end

    context 'when there are active consumers reported in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'consumers/performance'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_processes)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('shinra:1:1')
        expect(body).to include('/consumers/shinra:1:1/subscriptions')
        expect(body).to include('RSS')
        expect(body).to include('ID')
        expect(body).to include('Utilization')
        expect(body).to include('Threads')
        expect(body).to include('120 MB')
        expect(body).to include('5.6%')
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
        before { get 'consumers/performance' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include('shinra:0:0')
          expect(body).to include('shinra:1:1')
          expect(body).to include('shinra:11:11')
          expect(body).to include('shinra:12:12')
          expect(body.scan('shinra:').size).to eq(50)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we visit second page' do
        before { get 'consumers/performance?page=2' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include('shinra:32:32')
          expect(body).to include('shinra:34:34')
          expect(body).to include('shinra:35:35')
          expect(body).to include('shinra:35:35')
          expect(body.scan('shinra:').size).to eq(50)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we go beyond available pages' do
        before { get 'consumers/performance?page=100' }

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

  describe '#controls' do
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

  describe '#details' do
    context 'when details exist' do
      before { get 'consumers/shinra:1:1/details' }

      it do
        expect(response).to be_ok
        expect(body).to include('<code class="json p-0 m-0"')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when commanding is enabled' do
      before do
        Karafka::Web.config.commanding.active = true

        get 'consumers/shinra:1:1/details'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Trace')
        expect(body).to include('Quiet')
        expect(body).to include('Stop')
      end
    end

    context 'when commanding is disabled' do
      before do
        Karafka::Web.config.commanding.active = false

        get 'consumers/shinra:1:1/details'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('btn-lockable  btn-disabled')
        expect(body).to include('Trace')
        expect(body).to include('Quiet')
        expect(body).to include('Stop')
      end
    end

    context 'when trying to visit details of a process with incompatible schema' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        report[:schema_version] = '100.0'
        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/details'
      end

      it do
        expect(response.status).to eq(404)
      end
    end

    context 'when details exist written in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'consumers/shinra:1:1/details'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('<code class="json p-0 m-0"')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when given process does not exist' do
      before { get 'consumers/4e8f7174ae53/details' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end
  end

  describe 'jobs/ path redirect' do
    context 'when visiting the jobs/ path without type indicator' do
      before { get 'consumers/shinra:1:1/jobs' }

      it 'expect to redirect to running jobs page' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include('consumers/shinra:1:1/jobs/running')
      end
    end
  end

  describe '#subscriptions' do
    context 'when subscriptions exist' do
      before { get 'consumers/shinra:1:1/subscriptions' }

      it do
        expect(response).to be_ok
        expect(body).to include('Rebalance count')
        expect(body).to include('This process does not consume any')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when subscription has an unknown rebalance reason' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: true)

        sg = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        sg[:state][:rebalance_reason] = ''

        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/subscriptions'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Rebalance count')
        expect(body).to include('Unknown')
        expect(body).to include('This process does not consume any')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when subscriptions exist and was reported in a transactional fashion' do
      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'consumers/shinra:1:1/subscriptions'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('Rebalance count')
        expect(body).to include('This process does not consume any')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when trying to visit subscriptions of a process with incompatible schema' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        report[:schema_version] = '100.0'
        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/subscriptions'
      end

      it do
        expect(response.status).to eq(404)
      end
    end

    context 'when given process has no subscriptions at all' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)
        report['consumer_groups'] = {}

        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/subscriptions'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('This process is not subscribed to any topics')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when given process does not exist' do
      before do
        topics_config.consumers.reports.name = reports_topic

        get 'consumers/4e8f7174ae53/subscriptions'
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when subscription group has a static membership instance_id' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Set instance_id on the subscription group
        sg = report['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        sg['instance_id'] = 'my-static-member-456'

        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/subscriptions'
      end

      it do
        expect(response).to be_ok
        expect(body).to include('my-static-member-456')
        expect(body).to include('Static Membership ID')
        expect(body).to include('tooltip')
        expect(body).to include('Consumer Group')
        expect(body).to include('Subscription Group')
      end
    end

    context 'when subscription group does not have static membership' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        # Ensure instance_id is false (no static membership) on all subscription groups
        report['consumer_groups']['example_app6_app']['subscription_groups'].each_value do |sg|
          sg['instance_id'] = false
        end

        produce(reports_topic, report.to_json)

        get 'consumers/shinra:1:1/subscriptions'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include('Static Membership ID')
        # Tooltips for consumer group and subscription group should still be present
        expect(body).to include('Consumer Group')
        expect(body).to include('Subscription Group')
      end
    end
  end
end
