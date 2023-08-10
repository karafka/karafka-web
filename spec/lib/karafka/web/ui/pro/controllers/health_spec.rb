# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  describe '#index' do
    context 'when no report data' do
      before do
        topics_config.consumers.reports = create_topic
        get 'health'
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
      before { get 'health' }

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
end
