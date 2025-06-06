# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#index' do
    before { get 'routing' }

    it do
      expect(response).to be_ok
      expect(body).to include(topics_config.consumers.states.name)
      expect(body).to include(topics_config.consumers.metrics.name)
      expect(body).to include(topics_config.consumers.reports.name)
      expect(body).to include(topics_config.errors.name)
      expect(body).to include('karafka_web')
      expect(body).to include(breadcrumbs)
      expect(body).to include(support_message)
    end
  end

  describe '#show' do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it 'expect to display details, including the injectable once' do
      expect(response).to be_ok
      expect(body).to include('kafka.topic.metadata.refresh.interval.ms')
      expect(body).to include(breadcrumbs)
      expect(body).to include('kafka.statistics.interval.ms')
      expect(body).to include(support_message)
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
        t_name = generate_topic_name

        draw_routes do
          topic t_name do
            consumer Karafka::BaseConsumer
            kafka(
              'sasl.username': 'username',
              'sasl.password': 'password',
              'sasl.mechanisms': 'SCRAM-SHA-512',
              'bootstrap.servers': '127.0.0.1:9092'
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it 'expect to hide them' do
        expect(response).to be_ok
        expect(body).to include('kafka.sasl.username')
        expect(body).to include('***')
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when there are ssl details' do
      before do
        t_name = generate_topic_name

        draw_routes do
          topic t_name do
            consumer Karafka::BaseConsumer
            kafka(
              'ssl.key.password': 'password',
              'bootstrap.servers': '127.0.0.1:9092'
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it 'expect to hide them' do
        expect(response).to be_ok
        expect(body).to include('kafka.ssl.key.password')
        expect(body).to include('***')
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end
  end
end
