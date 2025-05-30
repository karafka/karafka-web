# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:reports_topic) { create_topic }

  let(:partition_scope) do
    %w[
      consumer_groups
      example_app6_app
      subscription_groups
      c4ca4238a0b9_0
      topics
      default
      partitions
      0
    ]
  end

  describe '#overview' do
    context 'when no report data' do
      before do
        topics_config.consumers.reports.name = reports_topic
        get 'health/overview'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('No health data is available')
      end
    end

    context 'when data is present' do
      before { get 'health/overview' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('327355')
      end

      context 'when sorted' do
        before { get 'health/overview?sort=id+desc' }

        it { expect(response).to be_ok }
      end
    end

    context 'when data is present but written in a transactional fashion' do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'health/overview'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('327355')
      end
    end
  end

  describe '#lags' do
    context 'when no report data' do
      before do
        topics_config.consumers.reports.name = reports_topic

        get 'health/lags'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('No health data is available')
        expect(body).not_to include('badge-warning')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when data is present' do
      before { get 'health/lags' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('213731273')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when data is present but reported in a transactional fashion' do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'health/lags'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('213731273')
        expect(body).not_to include('badge-error')
      end
    end
  end

  describe '#cluster_lags' do
    context 'when no report data' do
      before do
        allow(Karafka::Admin).to receive(:read_lags_with_offsets).and_return({})
        get 'health/cluster_lags'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('No health data is available')
        expect(body).not_to include('badge-warning')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when we have groups and data but topics never consumed' do
      before { get 'health/lags' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('-1')
      end
    end
  end

  describe '#offsets' do
    context 'when no report data' do
      before do
        topics_config.consumers.reports.name = reports_topic

        get 'health/offsets'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('No health data is available')
        expect(body).not_to include('badge-warning')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when data is present' do
      before { get 'health/offsets' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('327355')
        expect(body).not_to include('badge-warning')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when data is present but reported in a transactional fashion' do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'health/offsets'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('327355')
        expect(body).not_to include('badge-warning')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when one of partitions is at risk due to LSO' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)

        partition_data['committed_offset'] = 1_000
        partition_data['ls_offset'] = 3_000
        partition_data['ls_offset_fd'] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get 'health/offsets'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('badge-warning')
        expect(body).to include('at_risk')
        expect(body).not_to include('badge-error')
        expect(body).not_to include('stopped')
      end
    end

    context 'when one of partitions is stopped due to LSO' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)

        partition_data['committed_offset'] = 3_000
        partition_data['ls_offset'] = 3_000
        partition_data['ls_offset_fd'] = 1_000_000_000

        produce(reports_topic, report.to_json)

        get 'health/offsets'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('badge-error')
        expect(body).to include('stopped')
        expect(body).not_to include('at_risk')
        expect(body).not_to include('badge-warning')
      end
    end
  end

  describe '#changes' do
    context 'when no report data' do
      before do
        topics_config.consumers.reports.name = reports_topic

        get 'health/changes'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('No health data is available')
        expect(body).not_to include('badge-warning')
        expect(body).not_to include('badge-error')
      end
    end

    context 'when data is present' do
      before { get 'health/changes' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Pause state change')
        expect(body).to include('N/A')
        expect(body).to include('2690818656.575513')
      end
    end

    context 'when data is present but reported in a transactional fashion' do
      before do
        topics_config.consumers.reports.name = reports_topic
        produce(reports_topic, Fixtures.consumers_reports_file, type: :transactional)

        get 'health/changes'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Pause state change')
        expect(body).to include('Changes')
      end
    end

    context 'when one of partitions is paused forever' do
      before do
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json(symbolize_names: false)

        partition_data = report.dig(*partition_scope)

        partition_data['poll_state'] = 'paused'
        partition_data['poll_state_ch'] = 1_000_000_000_000

        produce(reports_topic, report.to_json)

        get 'health/changes'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Until manual resume')
      end
    end
  end
end
