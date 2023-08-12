# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  context 'when the state data is missing' do
    before do
      topics_config.consumers.states = create_topic

      get 'dashboard'
    end

    it do
      expect(response).not_to be_ok
      expect(status).to eq(404)
    end
  end

  context 'when there is no data to display' do
    let(:states_topic) { create_topic }
    let(:metrics_topic) { create_topic }

    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.metrics = metrics_topic

      defaults = ::Karafka::Web::Management::CreateInitialStates

      produce(states_topic, defaults::DEFAULT_STATE.to_json)
      produce(metrics_topic, defaults::DEFAULT_METRICS.to_json)

      get 'dashboard'
    end

    it do
      expect(response).to be_ok
      expect(body).to include('There needs to be more data to draw meaningful graphs')
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include('id="counters"')
    end
  end

  context 'when there is only one data sample in metrics' do
    let(:states_topic) { create_topic }
    let(:metrics_topic) { create_topic }

    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.metrics = metrics_topic

      defaults = ::Karafka::Web::Management::CreateInitialStates

      produce(states_topic, defaults::DEFAULT_STATE.to_json)
      produce(metrics_topic, fixtures_file('consumers_single_metrics.json'))

      get 'dashboard'
    end

    it do
      expect(response).to be_ok
      expect(body).to include('There needs to be more data to draw meaningful graphs')
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include('id="counters"')
    end
  end

  context 'when there is enough data' do
    before { get 'dashboard' }

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include(only_pro_feature)
      expect(body).to include('Topics pace')
      expect(body).to include('Batches')
      expect(body).to include('Message')
      expect(body).to include('id="counters"')
    end
  end
end
