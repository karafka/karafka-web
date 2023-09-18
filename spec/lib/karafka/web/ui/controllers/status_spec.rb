# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#show' do
    context 'when all that is needed is there' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include('The initial state of the consumers appears to')
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
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when replication factor is less than 2 in production' do
      before do
        allow(Karafka.env).to receive(:production?).and_return(true)
        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('Please ensure all those topics have a replication')
        expect(body).to include('Warning')
      end
    end

    context 'when replication factor is less than 2 in non-production' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include('Please ensure all those topics have a replication')
      end
    end

    context 'when consumers states topic received corrupted data' do
      let(:states_topic) { create_topic }

      before do
        topics_config.consumers.states = states_topic
        # Corrupted on purpose
        produce(states_topic, '{')

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('The initial state of the consumers appears to')
      end
    end

    context 'when consumers metrics topic received corrupted data' do
      let(:metrics_topic) { create_topic }

      before do
        topics_config.consumers.metrics = metrics_topic
        produce(metrics_topic, '{')

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('The initial state of the consumers metrics appears to')
      end
    end
  end
end
