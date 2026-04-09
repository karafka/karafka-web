# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  let(:states_topic) { create_topic }
  let(:metrics_topic) { create_topic }

  context "when the state data is missing" do
    before do
      topics_config.consumers.states.name = create_topic

      get "dashboard"
    end

    it do
      refute(response.ok?)
      assert_equal(404, status)
    end
  end

  context "when there is no data to display" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      Karafka::Web::Management::Actions::MigrateStatesData.new.call
      wait_for_state_data

      get "dashboard"
    end

    it do
      assert(response.ok?)
      assert_body("There Needs to Be More Data to Draw Meaningful Graphs")
      assert_body(support_message)
      refute_body(breadcrumbs)
      assert_body('id="refreshable"')
      assert_body('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context "when there is only one data sample in metrics" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      produce(metrics_topic, Fixtures.consumers_metrics_file("v1.3.0_single.json"))
      Karafka::Web::Management::Actions::MigrateStatesData.new.call
      wait_for_state_data

      get "dashboard"
    end

    it do
      assert(response.ok?)
      assert_body("There Needs to Be More Data to Draw Meaningful Graphs")
      assert_body(support_message)
      refute_body(breadcrumbs)
      assert_body('id="refreshable"')
      assert_body('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context "when there is enough data" do
    before { get "dashboard" }

    it do
      assert(response.ok?)
      assert_body(support_message)
      refute_body(breadcrumbs)
      assert_body(only_pro_feature)
      assert_body("Pace")
      assert_body("Batches")
      assert_body("Jobs")
      assert_body("Consumed")
      assert_body("Max LSO")
      assert_body("Utilization")
      assert_body("RSS")
      assert_body("Concurrency")
      assert_body("Data transfers")
      assert_body('id="refreshable"')
      assert_body('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  # Transactionals have the management offset taken, hence we check it to make sure, that we have
  # means in the UI to compensate for that
  context "when there is enough data written in a transaction" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      produce(states_topic, Fixtures.consumers_states_file, type: :transactional)
      produce(metrics_topic, Fixtures.consumers_metrics_file, type: :transactional)

      get "dashboard"
    end

    it do
      assert(response.ok?)
      assert_body(support_message)
      refute_body(breadcrumbs)
      assert_body(only_pro_feature)
      assert_body("Pace")
      assert_body("Batches")
      assert_body("Jobs")
      assert_body("Consumed")
      assert_body("Max LSO")
      assert_body("Utilization")
      assert_body("RSS")
      assert_body("Concurrency")
      assert_body("Data transfers")
      assert_body('id="refreshable"')
      assert_body('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end
end
