# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:app) { Karafka::Web::Pro::Ui::App }

  describe "#show" do
    context "when all that is needed is there" do
      before { get "status" }

      it do
        assert(response.ok?)
        refute_body(support_message)
        assert_body(breadcrumbs)
      end
    end

    context "when topics are missing" do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get "status"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        assert_body(breadcrumbs)
      end
    end

    context "when topics exist with data" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }
      let(:errors_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic
        topics_config.errors.name = errors_topic

        Karafka::Web::Management::Actions::CreateInitialStates.new.call
        produce(metrics_topic, Fixtures.consumers_metrics_file)
        Karafka::Web::Management::Actions::MigrateStatesData.new.call

        get "status"
      end

      it "displays successful status with topic information" do
        assert(response.ok?)
        assert_body("Status")
        refute_body(support_message)
        assert_body(breadcrumbs)
        assert_body(states_topic)
        assert_body(metrics_topic)
        assert_body(reports_topic)
        assert_body(errors_topic)
      end

      it "shows connection details" do
        assert_body("Components info")
        assert_body("rdkafka")
        assert_body("karafka")
      end

      it "shows version information" do
        assert_body(Karafka::VERSION)
        assert_body(Karafka::Web::VERSION)
      end
    end

    context "when commands topic is missing" do
      before do
        topics_config.consumers.commands.name = generate_topic_name

        get "status"
      end

      it do
        assert(response.ok?)
        assert_body("Commands topic presence")
        assert_body("does not exist")
        assert_body("required for Pro commanding features")
        assert_body("alert-box-warning")
      end
    end
  end
end
