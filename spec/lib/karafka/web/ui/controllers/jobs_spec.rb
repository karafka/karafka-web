# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

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
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end
  end
end
