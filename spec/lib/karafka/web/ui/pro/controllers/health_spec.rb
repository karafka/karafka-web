# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

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
        topics_config.consumers.reports = reports_topic
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
    end

    context 'when data is present but written in a transactional fashion' do
      before do
        topics_config.consumers.reports = reports_topic
        produce(reports_topic, Fixtures.file('consumer_report.json'), type: :transactional)

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

  describe '#offsets' do
    context 'when no report data' do
      before do
        topics_config.consumers.reports = reports_topic

        get 'health/offsets'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('No health data is available')
        expect(body).not_to include('bg-warning')
        expect(body).not_to include('bg-danger')
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
        expect(body).not_to include('bg-warning')
        expect(body).not_to include('bg-danger')
      end
    end

    context 'when data is present but reported in a transactional fashion' do
      before do
        topics_config.consumers.reports = reports_topic
        produce(reports_topic, Fixtures.file('consumer_report.json'), type: :transactional)

        get 'health/offsets'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not available until first offset')
        expect(body).to include('327355')
        expect(body).not_to include('bg-warning')
        expect(body).not_to include('bg-danger')
      end
    end

    context 'when one of partitions is at risk due to LSO' do
      before do
        report = Fixtures.json('consumer_report', symbolize_names: false)

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
        expect(body).to include('bg-warning')
        expect(body).to include('at_risk')
        expect(body).not_to include('bg-danger')
        expect(body).not_to include('stopped')
      end
    end

    context 'when one of partitions is stopped due to LSO' do
      before do
        report = Fixtures.json('consumer_report', symbolize_names: false)

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
        expect(body).to include('bg-danger')
        expect(body).to include('stopped')
        expect(body).not_to include('at_risk')
        expect(body).not_to include('bg-warning')
      end
    end
  end
end
