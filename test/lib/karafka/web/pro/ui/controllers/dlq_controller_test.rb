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

describe_current do
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic_name) { generate_topic_name }

  before { Karafka::Web.config.ui.dlq_patterns = [/#{topic_name}-dlq/] }

  describe "#index" do
    context "when there are no dlq topics" do
      before { get "dlq" }

      it do
        assert(response.ok?)
        assert_body("No Dead Letter Queue topics exist in Kafka")
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when there are dlq topics" do
      let(:topic) { Karafka::App.consumer_groups.first.topics.first }
      let(:dlq_topic) { Karafka::App.consumer_groups.last.topics.first.name }

      before do
        allow(topic.dead_letter_queue).to receive(:topic).and_return(dlq_topic)

        get "dlq"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(dlq_topic)
        refute_body("No Dead Letter Queue topics exist in Kafka")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when defined DLQ name matches the topic name with a postfix" do
      let(:topic) { Karafka::App.consumer_groups.first.topics.first }
      let(:dlq_topic) { "#{topic.name}.dql" }

      before do
        allow(topic.dead_letter_queue).to receive(:topic).and_return(dlq_topic)

        create_topic(topic_name: dlq_topic)

        get "dlq"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(dlq_topic)
        refute_body("#{topic.name}\"")
        refute_body("No Dead Letter Queue topics exist in Kafka")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when there are topics matching the DLQ auto-discovery" do
      let(:topic) { create_topic(topic_name: topic_name) }
      let(:dlq_topic) { create_topic(topic_name: "#{topic_name}-dlq") }

      before do
        topic
        dlq_topic
        get "dlq"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(dlq_topic)
        refute_body("No Dead Letter Queue topics exist in Kafka")
        refute_body(pagination)
        refute_body(support_message)
        refute_body("#{topic_name}\"")
      end
    end
  end
end
