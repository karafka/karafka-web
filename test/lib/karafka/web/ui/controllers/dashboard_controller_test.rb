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

      get "dashboard"
    end

    it do
      assert(response.ok?)
      assert_includes(body, "There Needs to Be More Data to Draw Meaningful Graphs")
      assert_includes(body, support_message)
      refute_includes(body, breadcrumbs)
      assert_includes(body, 'id="refreshable"')
      assert_includes(body, '<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context "when there is only one data sample in metrics" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      produce(metrics_topic, Fixtures.consumers_metrics_file("v1.3.0_single.json"))
      Karafka::Web::Management::Actions::MigrateStatesData.new.call

      get "dashboard"
    end

    it do
      assert(response.ok?)
      assert_includes(body, "There Needs to Be More Data to Draw Meaningful Graphs")
      assert_includes(body, support_message)
      refute_includes(body, breadcrumbs)
      assert_includes(body, 'id="refreshable"')
      assert_includes(body, '<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context "when there is enough data" do
    before { get "dashboard" }

    it do
      assert(response.ok?)
      assert_includes(body, support_message)
      refute_includes(body, breadcrumbs)
      assert_includes(body, only_pro_feature)
      assert_includes(body, "Pace")
      assert_includes(body, "Batches")
      assert_includes(body, "Jobs")
      assert_includes(body, "Consumed")
      assert_includes(body, "Max LSO")
      assert_includes(body, "Utilization")
      assert_includes(body, "RSS")
      assert_includes(body, "Concurrency")
      assert_includes(body, "Data transfers")
      assert_includes(body, 'id="refreshable"')
      assert_includes(body, '<div id="refreshable" class="col-span-12 mb-10">')
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
      assert_includes(body, support_message)
      refute_includes(body, breadcrumbs)
      assert_includes(body, only_pro_feature)
      assert_includes(body, "Pace")
      assert_includes(body, "Batches")
      assert_includes(body, "Jobs")
      assert_includes(body, "Consumed")
      assert_includes(body, "Max LSO")
      assert_includes(body, "Utilization")
      assert_includes(body, "RSS")
      assert_includes(body, "Concurrency")
      assert_includes(body, "Data transfers")
      assert_includes(body, 'id="refreshable"')
      assert_includes(body, '<div id="refreshable" class="col-span-12 mb-10">')
    end
  end
end
