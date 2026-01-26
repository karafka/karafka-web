# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:states_topic) { create_topic }
  let(:metrics_topic) { create_topic }
  let(:no_meaningful) { "There Needs to Be More Data to Draw Meaningful Graphs" }

  context "when the state data is missing" do
    before do
      topics_config.consumers.states.name = create_topic

      get "dashboard"
    end

    it do
      expect(response).not_to be_ok
      expect(status).to eq(404)
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
      expect(response).to be_ok
      expect(body).to include(no_meaningful)
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
      expect(body).not_to include(support_message)
      expect(body).not_to include(breadcrumbs)
    end
  end

  context "when there is only one data sample in metrics" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      produce(metrics_topic, Fixtures.consumers_metrics_file("v1.0.0_single.json"))
      Karafka::Web::Management::Actions::MigrateStatesData.new.call

      get "dashboard"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(no_meaningful)
      expect(body).not_to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
    end
  end

  context "when there is enough data" do
    before { get "dashboard" }

    it do
      expect(response).to be_ok
      expect(body).to include("Pace")
      expect(body).to include("Batches")
      expect(body).to include("Jobs")
      expect(body).to include("Consumed")
      expect(body).to include("Max LSO")
      expect(body).to include("Utilization")
      expect(body).to include("RSS")
      expect(body).to include("Concurrency")
      expect(body).to include("Data transfers")
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
      expect(body).not_to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).not_to include(only_pro_feature)
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
      expect(response).to be_ok
      expect(body).to include("Pace")
      expect(body).to include("Batches")
      expect(body).to include("Jobs")
      expect(body).to include("Consumed")
      expect(body).to include("Max LSO")
      expect(body).to include("Utilization")
      expect(body).to include("RSS")
      expect(body).to include("Concurrency")
      expect(body).to include("Data transfers")
      expect(body).to include('id="refreshable"')
      expect(body).to include('<div id="refreshable" class="col-span-12 mb-10">')
      expect(body).not_to include(support_message)
      expect(body).not_to include(breadcrumbs)
      expect(body).not_to include(only_pro_feature)
    end
  end

  # https://github.com/karafka/karafka-web/issues/356
  context "when there are gaps in pace" do
    before do
      topics_config.consumers.states.name = states_topic
      topics_config.consumers.metrics.name = metrics_topic

      Karafka::Web::Management::Actions::CreateInitialStates.new.call
      produce(metrics_topic, Fixtures.consumers_metrics_file("v1.3.0_pace_gaps.json"))
      Karafka::Web::Management::Actions::MigrateStatesData.new.call

      get "dashboard"
    end

    it do
      expect(response).to be_ok
    end
  end
end
