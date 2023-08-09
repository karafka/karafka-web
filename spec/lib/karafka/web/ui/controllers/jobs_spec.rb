# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#index' do
    context 'when needed topics are missing' do
      before do
        ::Karafka::Web.config.topics.consumers.states = SecureRandom.uuid
        ::Karafka::Web.config.topics.consumers.metrics = SecureRandom.uuid
        ::Karafka::Web.config.topics.consumers.reports = SecureRandom.uuid
        ::Karafka::Web.config.topics.errors = SecureRandom.uuid

        get 'jobs'
      end

      it { expect(last_response).not_to be_ok }
      it { expect(last_response.status).to eq(404) }
    end

    context 'when needed topics are present' do
      before { get 'jobs' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include('2023-08-01T09:47:51') }
      it { expect(last_response.body).to include('ActiveJob::Consumer') }
      it { expect(last_response.body).to include('Please help us') }
    end
  end
end
