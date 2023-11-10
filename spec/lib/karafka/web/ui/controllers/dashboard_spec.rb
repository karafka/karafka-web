# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:states_topic) { create_topic }
  let(:metrics_topic) { create_topic }

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
    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.metrics = metrics_topic

      ::Karafka::Web::Management::Actions::CreateInitialStates.new.call
      ::Karafka::Web::Management::Actions::MigrateStatesData.new.call

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
    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.metrics = metrics_topic

      ::Karafka::Web::Management::Actions::CreateInitialStates.new.call
      ::Karafka::Web::Management::Actions::MigrateStatesData.new.call

      produce(metrics_topic, Fixtures.file('consumers_single_metrics.json'))

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

  # Transactionals have the management offset taken, hence we check it to make sure, that we have
  # means in the UI to compensate for that
  context 'when there is enough data written in a transaction' do
    before do
      topics_config.consumers.states = states_topic
      topics_config.consumers.metrics = metrics_topic

      produce(states_topic, Fixtures.file('consumers_state.json'), type: :transactional)
      produce(metrics_topic, Fixtures.file('consumers_metrics.json'), type: :transactional)

      get 'dashboard'
    end

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
