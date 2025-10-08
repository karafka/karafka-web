# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:states_topic) { create_topic }
  let(:metrics_topic) { create_topic }

  context 'when the state data is missing' do
    before do
      topics_config.consumers.states.name = create_topic

      get 'dashboard'
    end

    it do
      expect(response).not_to be_ok
      expect(status).to eq(404)
    end
  end

  context 'when there is no data to display' do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      Karafka::Web::Management::Actions::MigrateStatesData.new.call

      get 'dashboard'
    end

    it do
      expect(response).to be_ok
      expect(body).to include('There Needs to Be More Data to Draw Meaningful Graphs')
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context 'when there is only one data sample in metrics' do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      produce(metrics_topic, Fixtures.consumers_metrics_file('v1.3.0_single.json'))
      Karafka::Web::Management::Actions::MigrateStatesData.new.call

      get 'dashboard'
    end

    it do
      expect(response).to be_ok
      expect(body).to include('There Needs to Be More Data to Draw Meaningful Graphs')
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context 'when there is enough data' do
    before { get 'dashboard' }

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include(only_pro_feature)
      expect(body).to include('Pace')
      expect(body).to include('Batches')
      expect(body).to include('Jobs')
      expect(body).to include('Consumed')
      expect(body).to include('Max LSO')
      expect(body).to include('Utilization')
      expect(body).to include('RSS')
      expect(body).to include('Concurrency')
      expect(body).to include('Data transfers')
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  # Transactionals have the management offset taken, hence we check it to make sure, that we have
  # means in the UI to compensate for that
  context 'when there is enough data written in a transaction' do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
      produce(metrics_topic, Fixtures.consumers_metrics_file, type: :transactional)

      get 'dashboard'
    end

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include(only_pro_feature)
      expect(body).to include('Pace')
      expect(body).to include('Batches')
      expect(body).to include('Jobs')
      expect(body).to include('Consumed')
      expect(body).to include('Max LSO')
      expect(body).to include('Utilization')
      expect(body).to include('RSS')
      expect(body).to include('Concurrency')
      expect(body).to include('Data transfers')
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end
end
