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

  let(:topic_name) { generate_topic_name }

  before { Karafka::Web.config.ui.dlq_patterns = [/#{topic_name}-dlq/] }

  describe '#index' do
    context 'when there are no dlq topics' do
      before { get 'dlq' }

      it do
        expect(response).to be_ok
        expect(body).to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are dlq topics' do
      let(:topic) { Karafka::App.consumer_groups.first.topics.first }
      let(:dlq_topic) { Karafka::App.consumer_groups.last.topics.first.name }

      before do
        allow(topic.dead_letter_queue).to receive(:topic).and_return(dlq_topic)

        get 'dlq'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(dlq_topic)
        expect(body).not_to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when defined DLQ name matches the topic name with a postfix' do
      let(:topic) { Karafka::App.consumer_groups.first.topics.first }
      let(:dlq_topic) { "#{topic.name}.dql" }

      before do
        allow(topic.dead_letter_queue).to receive(:topic).and_return(dlq_topic)

        create_topic(topic_name: dlq_topic)

        get 'dlq'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(dlq_topic)
        expect(body).not_to include("#{topic.name}\"")
        expect(body).not_to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are topics matching the DLQ auto-discovery' do
      let(:topic) { create_topic(topic_name: topic_name) }
      let(:dlq_topic) { create_topic(topic_name: "#{topic_name}-dlq") }

      before do
        topic
        dlq_topic
        get 'dlq'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(dlq_topic)
        expect(body).not_to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include("#{topic_name}\"")
      end
    end
  end
end
