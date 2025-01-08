# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe '#index' do
    context 'when running against defaults' do
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

    context 'when there is no consumers state' do
      before do
        allow(Karafka::Web::Ui::Models::ConsumersState).to receive(:current).and_return(false)

        get 'routing'
      end

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

    context 'when there are states and reports' do
      let(:states_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states = states_topic
        topics_config.consumers.reports = reports_topic

        report = Fixtures.consumers_reports_json
        scope = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        base = scope[:topics][:default][:partitions]

        5.times { |i| base[i + 1] = base[:'0'].dup.merge(id: i + 1) }

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get 'routing'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(topics_config.errors)
        expect(body).to include('karafka_web')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe '#show' do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it 'expect to display details, including the injectable once' do
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
              'sasl.mechanisms': 'SCRAM-SHA-512',
              'bootstrap.servers': '127.0.0.1:80'
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
            kafka(
              'ssl.key.password': 'password',
              'bootstrap.servers': '127.0.0.1:80'
            )
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
