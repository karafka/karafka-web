# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#index' do
    before { get 'routing' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include(Karafka::Web.config.topics.consumers.states) }
    it { expect(last_response.body).to include(Karafka::Web.config.topics.consumers.metrics) }
    it { expect(last_response.body).to include(Karafka::Web.config.topics.consumers.reports) }
    it { expect(last_response.body).to include(Karafka::Web.config.topics.errors) }
    it { expect(last_response.body).to include('karafka_web') }
  end

  describe '#show' do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include('kafka.topic.metadata.refresh.interval.ms') }
    it { expect(last_response.body).to include('Please help us') }

    context 'when given route is not available' do
      before { get 'routing/na' }

      it { expect(last_response).not_to be_ok }
      it { expect(last_response.status).to eq(404) }
    end
  end
end
