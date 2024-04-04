# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  describe '#index' do
    before { get 'routing' }

    it do
      expect(response).to be_ok
      expect(body).to include(topics_config.consumers.states)
      expect(body).to include(topics_config.consumers.metrics)
      expect(body).to include(topics_config.consumers.reports)
      expect(body).to include(topics_config.errors)
      expect(body).to include('karafka_web')
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end
  end

  describe '#show' do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it do
      expect(response).to be_ok
      expect(body).to include('kafka.topic.metadata.refresh.interval.ms')
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end

    context 'when given route is not available' do
      before { get 'routing/na' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end
  end
end
