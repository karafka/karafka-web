# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:no_processes) { 'There are no Karafka consumer processes' }

  context 'when the state data is missing' do
    before do
      topics_config.consumers.states = create_topic

      get 'consumers'
    end

    it do
      expect(response).not_to be_ok
      expect(response.status).to eq(404)
    end
  end

  context 'when there are no active consumers' do
    before do
      topics_config.consumers.reports = create_topic

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

  context 'when there are more consumers that we fit on a single page' do
    pending
  end
end
