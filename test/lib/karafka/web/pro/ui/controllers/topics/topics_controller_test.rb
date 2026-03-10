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

  let(:internal_topic) { "__#{generate_topic_name}" }
  let(:cluster_topics) { Karafka::Admin.cluster_info.topics.map { |t| t[:topic_name] } }

  describe "#index" do
    before do
      create_topic(topic_name: internal_topic)
      get "topics"
    end

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      refute_body(pagination)
      refute_body(support_message)
      assert_body(topics_config.consumers.states.name)
      assert_body(topics_config.consumers.metrics.name)
      assert_body(topics_config.consumers.reports.name)
      assert_body(topics_config.errors.name)
      refute_body(internal_topic)
    end

    context "when there are no topics" do
      before do
        Karafka::Web::Ui::Models::Topic.stubs(:all).returns([])
        get "topics"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("There are no available topics in the current cluster")
      end
    end

    context "when internal topics should be displayed" do
      before do
        Karafka::Web.config.ui.visibility.stubs(:internal_topics).returns(true)

        get "topics"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body(topics_config.consumers.states.name)
        assert_body(topics_config.consumers.metrics.name)
        assert_body(topics_config.consumers.reports.name)
        assert_body(topics_config.errors.name)
        assert_body(internal_topic)
      end
    end
  end

  describe "#new" do
    context "when topics management feature is enabled" do
      before { get "topics/new" }

      it "renders successfully" do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Creating New Topic")
        assert_body("Topic Name:")
        assert_body("Number of Partitions:")
        assert_body("Replication Factor:")
        assert_body("Topic Creation Settings")
        assert_body("Topic name cannot be changed after creation")
        assert_body("Number of partitions can only be increased")
        assert_body('value="5"') # Default partitions count
        assert_body('value="1"') # Default replication factor
        assert_body('pattern="[A-Za-z0-9\-_.]+"') # Topic name pattern
        assert_body('maxlength="249"') # Topic name length limit
        assert_body('min="1"') # Minimum partitions/replication
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false

        get "topics/new"
      end

      it "returns unauthorized status" do
        refute(response.ok?)
        assert_equal(403, status)
      end
    end

    context "when form was previously submitted with errors" do
      before do
        get(
          "topics/new",
          topic_name: "invalid-topic",
          partitions_count: "2",
          replication_factor: "1"
        )
      end

      it "preserves the submitted values" do
        assert_body('value="invalid-topic"')
        assert_body('value="2"')
        assert_body('value="1"')
      end
    end
  end

  describe "#create" do
    let(:topic_name) { generate_topic_name }
    let(:partitions_count) { 3 }
    let(:replication_factor) { 1 }
    let(:default_params) do
      {
        topic_name: topic_name,
        partitions_count: partitions_count,
        replication_factor: replication_factor
      }
    end

    context "when topics management feature is enabled and data is correct" do
      before { post "topics", default_params }

      it "creates topic successfully" do
        assert_equal(302, response.status)
        assert(response.location.end_with?("/topics"))
        assert_includes(flash[:success], "Topic #{topic_name} successfully created")
        assert_includes(cluster_topics, topic_name)
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        post "topics", default_params
      end

      it "returns unauthorized status" do
        refute(response.ok?)
        assert_equal(403, status)
      end
    end

    context "when topic creation fails because of rdkafka error" do
      let(:topic_name) { cluster_topics.first }
      let(:error_message) { "Topic already exists" }

      before { post "topics", default_params }

      it "renders form with errors" do
        assert(response.ok?)
        assert_body("Creating New Topic")
        assert_body("Please Correct the Following Errors Before Continuing")
        assert_body(error_message)
        assert_body("value=\"#{topic_name}\"")
        assert_body("value=\"#{partitions_count}\"")
        assert_body("value=\"#{replication_factor}\"")
      end
    end

    context "with parameter validation" do
      [
        { topic_name: "" },
        { partitions_count: 0 },
        { replication_factor: 0 }
      ].each do |params_override|
        context "with invalid #{params_override.keys.first}" do
          before { post "topics", default_params.merge(params_override) }

          it "renders form" do
            assert(response.ok?)
            assert_body("Creating New Topic")
          end
        end
      end
    end

    context "with topic name validation" do
      {
        "valid-topic" => true,
        "valid.topic" => true,
        "valid_topic" => true,
        "Valid123" => true,
        "invalid topic" => false,
        "invalid#topic" => false,
        "invalid@topic" => false,
        "a" * 250 => false
      }.each do |topic_name_val, expected_success|
        context "with topic name #{topic_name_val[0, 20]}" do
          before do
            Karafka::Admin.stubs(:create_topic) if expected_success
            post "topics", default_params.merge(topic_name: topic_name_val)
          end

          it "handles as expected" do
            if expected_success
              assert_equal(302, response.status)
              assert(response.location.end_with?("/topics"))
            else
              assert(response.ok?)
              assert_body("Creating New Topic")
            end
          end
        end
      end
    end
  end

  describe "#edit" do
    let(:topic_name) { generate_topic_name }
    let(:setup_topic) { create_topic(topic_name: topic_name) }

    context "when topics management feature is enabled" do
      before do
        setup_topic
        get "topics/#{topic_name}/delete"
      end

      it "renders removal confirmation page with all required elements" do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Topic #{topic_name} Removal Confirmation")
        refute_body(pagination)
        refute_body(support_message)

        # Topic details
        assert_body("You are about to delete topic:")
        assert_body(topic_name)

        # Warning messages
        assert_body("Topic Removal Warning")
        assert_body("All data in this topic will be permanently deleted")
        assert_body("All consumers and producers for this topic will stop functioning")
        assert_body("Consumer group offsets associated with this topic will be lost")

        # Pre-deletion checklist
        assert_body("Before proceeding, ensure that:")
        assert_body("All applications consuming from this topic have been properly")
        assert_body("All producers to this topic have been stopped")
        assert_body("You have backed up any critical data if needed")
        assert_body("You have notified relevant team members about this deletion")

        # Form elements
        assert_body('method="post"')
        assert_body('type="hidden"')
        assert_body('name="_method" value="delete"')
        assert_body("Delete Topic")
        assert_body("Cancel")
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        get "topics/#{topic_name}/delete"
      end

      it "returns unauthorized status" do
        refute(response.ok?)
        assert_equal(403, status)
      end
    end

    context "when topic does not exist" do
      before { get "topics/non-existent-topic/delete" }

      it "returns not found status" do
        assert_equal(404, status)
      end
    end
  end

  describe "#delete" do
    let(:topic_name) { generate_topic_name }
    let(:setup_topic) { create_topic(topic_name: topic_name) }

    context "when topics management feature is enabled" do
      before do
        setup_topic
        delete "topics/#{topic_name}"
      end

      it "deletes topic and redirects with success message" do
        assert_equal(302, response.status)
        assert(response.location.end_with?("/topics"))
        assert_includes(flash[:success], "Topic #{topic_name} successfully deleted")
        refute_includes(cluster_topics, topic_name)
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        delete "topics/#{topic_name}"
      end

      it "returns unauthorized status" do
        refute(response.ok?)
        assert_equal(403, status)
      end
    end

    context "when topic does not exist" do
      before { delete "topics/non-existent-topic" }

      it "returns not found status" do
        assert_equal(404, status)
      end
    end
  end
end
