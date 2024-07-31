# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

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

    it do 'expect to display details, including the injectable once'
      expect(response).to be_ok
      expect(body).to include('kafka.topic.metadata.refresh.interval.ms')
      expect(body).to include(breadcrumbs)
      expect(body).to include('kafka.statistics.interval.ms')
      expect(body).not_to include(support_message)
    end

    context 'when given route is not available' do
      before { get 'routing/na' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there are saml details' do
      before do
        draw_routes do
          topic SecureRandom.uuid do
            consumer Karafka::BaseConsumer
            kafka(
              'sasl.username': 'username',
              'sasl.password': 'password',
              'sasl.mechanisms': 'SCRAM-SHA-512'
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it 'expect to hide them' do
        expect(response).to be_ok
        expect(body).to include('kafka.sasl.username')
        expect(body).to include('***')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are ssl details' do
      before do
        draw_routes do
          topic SecureRandom.uuid do
            consumer Karafka::BaseConsumer
            kafka('ssl.key.password': 'password')
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it 'expect to hide them' do
        expect(response).to be_ok
        expect(body).to include('kafka.ssl.key.password')
        expect(body).to include('***')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
      end
    end
  end
end
