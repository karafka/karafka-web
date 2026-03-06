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

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe "#show" do
    let(:no_data_msg) { "Those partitions are empty and do not contain any data" }
    let(:many_partitions_msg) { "distribution results are computed based only" }

    context "when trying to read distribution of a non-existing topic" do
      before { get "topics/#{generate_topic_name}/distribution" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when getting distribution of an existing empty topic" do
      before { get "topics/#{topic}/distribution" }

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        refute_includes(body, "chartjs-bar")
        assert_includes(body, topic)
        assert_includes(body, no_data_msg)
      end
    end

    context "when getting distribution of an existing empty topic with multiple partitions" do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/distribution" }

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        refute_includes(body, "chartjs-bar")
        assert_includes(body, topic)
        assert_includes(body, no_data_msg)
        assert_includes(body, many_partitions_msg)
      end
    end

    context "when getting distribution of an existing topic with one partition and data" do
      before do
        produce_many(topic, Array.new(100, ""))
        get "topics/#{topic}/distribution"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        refute_includes(body, "chartjs-bar")
        assert_includes(body, topic)
        assert_includes(body, "100.0%")
        refute_includes(body, no_data_msg)
      end
    end

    context "when getting distribution of an existing topic with few partitions and data" do
      let(:partitions) { 5 }

      before do
        5.times { |i| produce_many(topic, Array.new(100, ""), partition: i) }

        get "topics/#{topic}/distribution"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "chartjs-bar")
        assert_includes(body, topic)
        assert_includes(body, "20.0%")
        refute_includes(body, no_data_msg)
        refute_includes(body, many_partitions_msg)
      end
    end

    context "when getting distribution of an existing topic with many partitions and data" do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ""), partition: i) }

        get "topics/#{topic}/distribution"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "chartjs-bar")
        assert_includes(body, topic)
        assert_includes(body, "4.0%")
        refute_includes(body, no_data_msg)
        assert_includes(body, many_partitions_msg)
      end
    end

    context "when getting distribution of a topic with many partitions and data page 2" do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ""), partition: i) }

        get "topics/#{topic}/distribution?page=2"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "chartjs-bar")
        assert_includes(body, topic)
        assert_includes(body, "4.0%")
        assert_includes(body, '/25">')
        refute_includes(body, no_data_msg)
        assert_includes(body, many_partitions_msg)
      end
    end
  end

  describe "#edit" do
    let(:topic_name) { generate_topic_name }
    let(:setup_topic) { create_topic(topic_name: topic_name) }

    context "when topics management feature is enabled" do
      before do
        setup_topic
        get "topics/#{topic_name}/distribution/edit"
      end

      it "renders partition increase form with all required elements" do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Topic #{topic_name} - Increase Partitions")
        refute_includes(body, pagination)
        refute_includes(body, support_message)

        # Current state
        assert_includes(body, "Current Partitions:")
        assert_includes(body, "3") # Current partition count

        # Form elements
        assert_includes(body, 'method="post"')
        assert_includes(body, 'name="_method" value="put"')
        assert_includes(body, 'name="partition_count"')
        assert_includes(body, 'min="2"') # Current + 1
        assert_includes(body, "Must be greater than current partition count")
        assert_includes(body, "Increase Partitions")
        assert_includes(body, "Cancel")

        # Warnings
        assert_includes(body, "Partition Update Warning")
        assert_includes(body, "Increasing partitions is a one-way operation")
        assert_includes(body, "Adding partitions affects message ordering")
        assert_includes(body, "Changes may take several minutes to be visible")

        # Hints
        assert_includes(body, "Before increasing partitions:")
        assert_includes(body, "Ensure all consumers support dynamic partition detection")
        assert_includes(body, "Consider increasing partitions during low-traffic periods")
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        get "topics/#{topic_name}/distribution/edit"
      end

      it "returns unauthorized status" do
        refute(response.ok?)
        assert_equal(403, status)
      end
    end

    context "when topic does not exist" do
      before { get "topics/non-existent-topic/distribution/edit" }

      it "returns not found status" do
        assert_equal(404, status)
      end
    end
  end

  describe "#update" do
    let(:topic_name) { generate_topic_name }
    let(:setup_topic) { create_topic(topic_name: topic_name) }
    let(:new_partition_count) { 5 }
    let(:default_params) do
      {
        partition_count: new_partition_count
      }
    end

    context "when topics management feature is enabled" do
      context "when update succeeds" do
        before do
          setup_topic
          put "topics/#{topic_name}/distribution", default_params
        end

        it "increases partitions and redirects with success message" do
          assert_equal(302, response.status)
          assert(response.location.end_with?("/topics/#{topic_name}/distribution"))
          expect(flash[:success])
            .to include("Topic #{topic_name} repartitioning to #{new_partition_count} partitions")

          sleep(1)

          updated_topic = Karafka::Web::Ui::Models::Topic.find(topic_name)

          assert_equal(new_partition_count, updated_topic.partition_count)
        end
      end

      context "with invalid partition count" do
        context "when partition count is equal to current" do
          before do
            setup_topic
            put "topics/#{topic_name}/distribution", partition_count: 1
          end

          it "renders edit form" do
            assert(response.ok?)
            assert_includes(body, "Topic")
            assert_includes(body, "Increase Partitions")
          end
        end

        context "when partition count is too high" do
          before do
            setup_topic
            put "topics/#{topic_name}/distribution", partition_count: 1_000_000
          end

          it "renders edit form with error" do
            assert(response.ok?)
            assert_includes(body, "Topic")
            assert_includes(body, "Increase Partitions")
            assert_includes(body, "new_total_cnt")
          end
        end
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        put "topics/#{topic_name}/distribution", default_params
      end

      it "returns unauthorized status" do
        refute(response.ok?)
        assert_equal(403, status)
      end
    end

    context "when topic does not exist" do
      before { put "topics/non-existent-topic/distribution", default_params }

      it "returns not found status" do
        assert_equal(404, status)
      end
    end
  end
end
