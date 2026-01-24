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

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe '#show' do
    let(:no_data_msg) { 'Those partitions are empty and do not contain any data' }
    let(:many_partitions_msg) { 'distribution results are computed based only' }

    context 'when trying to read distribution of a non-existing topic' do
      before { get "topics/#{generate_topic_name}/distribution" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting distribution of an existing empty topic' do
      before { get "topics/#{topic}/distribution" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include(no_data_msg)
      end
    end

    context 'when getting distribution of an existing empty topic with multiple partitions' do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/distribution" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of an existing topic with one partition and data' do
      before do
        produce_many(topic, Array.new(100, ''))
        get "topics/#{topic}/distribution"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('100.0%')
        expect(body).not_to include(no_data_msg)
      end
    end

    context 'when getting distribution of an existing topic with few partitions and data' do
      let(:partitions) { 5 }

      before do
        5.times { |i| produce_many(topic, Array.new(100, ''), partition: i) }

        get "topics/#{topic}/distribution"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('20.0%')
        expect(body).not_to include(no_data_msg)
        expect(body).not_to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of an existing topic with many partitions and data' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/#{topic}/distribution"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('4.0%')
        expect(body).not_to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of a topic with many partitions and data page 2' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/#{topic}/distribution?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('4.0%')
        expect(body).to include('/25">')
        expect(body).not_to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end
  end

  describe '#edit' do
    let(:topic_name) { generate_topic_name }
    let(:test_topic) { create_topic(topic_name: topic_name) }

    context 'when topics management feature is enabled' do
      before do
        test_topic
        get "topics/#{topic_name}/distribution/edit"
      end

      it 'renders partition increase form with all required elements' do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include("Topic #{topic_name} - Increase Partitions")
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)

        # Current state
        expect(body).to include('Current Partitions:')
        expect(body).to include('3') # Current partition count

        # Form elements
        expect(body).to include('method="post"')
        expect(body).to include('name="_method" value="put"')
        expect(body).to include('name="partition_count"')
        expect(body).to include('min="2"') # Current + 1
        expect(body).to include('Must be greater than current partition count')
        expect(body).to include('Increase Partitions')
        expect(body).to include('Cancel')

        # Warnings
        expect(body).to include('Partition Update Warning')
        expect(body).to include('Increasing partitions is a one-way operation')
        expect(body).to include('Adding partitions affects message ordering')
        expect(body).to include('Changes may take several minutes to be visible')

        # Hints
        expect(body).to include('Before increasing partitions:')
        expect(body).to include('Ensure all consumers support dynamic partition detection')
        expect(body).to include('Consider increasing partitions during low-traffic periods')
      end
    end

    context 'when topics management feature is not enabled' do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        get "topics/#{topic_name}/distribution/edit"
      end

      it 'returns unauthorized status' do
        expect(response).not_to be_ok
        expect(status).to eq(403)
      end
    end

    context 'when topic does not exist' do
      before { get 'topics/non-existent-topic/distribution/edit' }

      it 'returns not found status' do
        expect(status).to eq(404)
      end
    end
  end

  describe '#update' do
    let(:topic_name) { generate_topic_name }
    let(:test_topic) { create_topic(topic_name: topic_name) }
    let(:new_partition_count) { 5 }
    let(:default_params) do
      {
        partition_count: new_partition_count
      }
    end

    context 'when topics management feature is enabled' do
      context 'when update succeeds' do
        before do
          test_topic
          put "topics/#{topic_name}/distribution", default_params
        end

        it 'increases partitions and redirects with success message' do
          expect(response.status).to eq(302)
          expect(response.location).to end_with("/topics/#{topic_name}/distribution")
          expect(flash[:success])
            .to include("Topic #{topic_name} repartitioning to #{new_partition_count} partitions")

          sleep(1)

          updated_topic = Karafka::Web::Ui::Models::Topic.find(topic_name)
          expect(updated_topic.partition_count).to eq(new_partition_count)
        end
      end

      context 'with invalid partition count' do
        context 'when partition count is equal to current' do
          before do
            test_topic
            put "topics/#{topic_name}/distribution", partition_count: 1
          end

          it 'renders edit form' do
            expect(response).to be_ok
            expect(body).to include('Topic')
            expect(body).to include('Increase Partitions')
          end
        end

        context 'when partition count is too high' do
          before do
            test_topic
            put "topics/#{topic_name}/distribution", partition_count: 1_000_000
          end

          it 'renders edit form with error' do
            expect(response).to be_ok
            expect(body).to include('Topic')
            expect(body).to include('Increase Partitions')
            expect(body).to include('new_total_cnt')
          end
        end
      end
    end

    context 'when topics management feature is not enabled' do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        put "topics/#{topic_name}/distribution", default_params
      end

      it 'returns unauthorized status' do
        expect(response).not_to be_ok
        expect(status).to eq(403)
      end
    end

    context 'when topic does not exist' do
      before { put 'topics/non-existent-topic/distribution', default_params }

      it 'returns not found status' do
        expect(status).to eq(404)
      end
    end
  end
end
