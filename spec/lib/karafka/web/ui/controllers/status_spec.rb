# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#show' do
    context 'when all that is needed is there' do
      before { get 'status' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include('Please help us') }
    end

    context 'when topics are missing' do
      before do
        ::Karafka::Web.config.topics.consumers.states = SecureRandom.uuid
        ::Karafka::Web.config.topics.consumers.metrics = SecureRandom.uuid
        ::Karafka::Web.config.topics.consumers.reports = SecureRandom.uuid
        ::Karafka::Web.config.topics.errors = SecureRandom.uuid

        get 'status'
      end

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to include('Please help us') }
    end
  end
end
