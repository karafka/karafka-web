# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe '#show' do
    context 'when all that is needed is there' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when topics are missing' do
      before do
        topics_config.consumers.states = SecureRandom.uuid
        topics_config.consumers.metrics = SecureRandom.uuid
        topics_config.consumers.reports = SecureRandom.uuid
        topics_config.errors = SecureRandom.uuid

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end
  end
end
