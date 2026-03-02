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

  describe "#index" do
    context "when trying to read configs of a non-existing topic" do
      before { get "topics/#{generate_topic_name}/config" }

      it do
        refute_predicate(response, :ok?)
        assert_equal(404, status)
      end
    end

    context "when getting configs of an existing topic" do
      before { get "topics/#{topic}/config" }

      it do
        assert_predicate(response, :ok?)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, topic)
        assert_includes(body, "max.message.bytes")
        assert_includes(body, "retention.ms")
        assert_includes(body, "min.insync.replicas")
      end
    end
  end

  describe "#edit" do
    let(:topic_name) { generate_topic_name }
    let(:test_topic) { create_topic(topic_name: topic_name) }
    let(:property_name) { "cleanup.policy" }

    context "when topics management feature is enabled" do
      context "when property exists and is editable" do
        before do
          test_topic
          get "topics/#{topic_name}/config/#{property_name}/edit"
        end

        it "renders edit form with all required elements" do
          assert_predicate(response, :ok?)
          assert_includes(body, breadcrumbs)
          assert_includes(body, "Topic #{topic_name} - Edit #{property_name}")
          refute_includes(body, pagination)
          refute_includes(body, support_message)

          # Form elements and structure
          assert_includes(body, 'method="post"')
          assert_includes(body, 'name="_method" value="put"')
          assert_includes(body, "Update Property")
          assert_includes(body, "Cancel")

          # Warnings and hints
          assert_includes(body, "Configuration Update Warning")
          assert_includes(body, "Changing topic configurations may affect topic behavior")
          assert_includes(body, "Some changes may take time to propagate")
          assert_includes(body, "Before updating this configuration:")
        end
      end

      context "when property does not exist" do
        before do
          test_topic
          get "topics/#{topic_name}/config/non-existent-property/edit"
        end

        it "returns not found status" do
          assert_equal(404, status)
        end
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        get "topics/#{topic_name}/config/#{property_name}/edit"
      end

      it "returns unauthorized status" do
        refute_predicate(response, :ok?)
        assert_equal(403, status)
      end
    end

    context "when topic does not exist" do
      before { get "topics/non-existent-topic/config/cleanup.policy/edit" }

      it "returns not found status" do
        assert_equal(404, status)
      end
    end
  end

  describe "#update" do
    let(:topic_name) { generate_topic_name }
    let(:test_topic) { create_topic(topic_name: topic_name) }
    let(:property_name) { "max.message.bytes" }
    let(:property_value) { rand(1_000..100_000) }
    let(:default_params) { { property_value: property_value } }
    let(:updated_value) do
      Karafka::Web::Ui::Models::Topic.find(topic_name).configs.find do |config|
        config.name == "max.message.bytes"
      end.value
    end

    context "when topics management feature is enabled" do
      context "when update succeeds" do
        before do
          test_topic
          put "topics/#{topic_name}/config/#{property_name}", default_params
          sleep(1)
        end

        it "updates config and redirects with success message" do
          assert_equal(302, response.status)
          assert(response.location.end_with?("/topics/#{topic_name}/config"))
          assert_includes(flash[:success], "Topic #{topic_name} property #{property_name}")
          assert_equal(property_value.to_s, updated_value)
        end
      end

      context "when update fails" do
        let(:error_message) { "Invalid value" }
        let(:property_value) { "-1" }

        before do
          test_topic
          put "topics/#{topic_name}/config/#{property_name}", default_params
        end

        it "renders edit form with error messages" do
          assert_predicate(response, :ok?)
          assert_includes(body, "Configuration Update Warning")
          assert_includes(body, error_message)
          assert_includes(body, topic_name)
          assert_includes(body, property_name)
          assert_includes(body, property_value)
        end
      end
    end

    context "when topics management feature is not enabled" do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        put "topics/#{topic_name}/config/#{property_name}", default_params
      end

      it "returns unauthorized status" do
        refute_predicate(response, :ok?)
        assert_equal(403, status)
      end
    end

    context "when topic does not exist" do
      before { put "topics/non-existent-topic/config/cleanup.policy", default_params }

      it "returns not found status" do
        assert_equal(404, status)
      end
    end

    context "when property does not exist" do
      before do
        test_topic
        put "topics/#{topic_name}/config/non-existent-property", default_params
      end

      it "returns not found status" do
        assert_equal(404, status)
      end
    end
  end
end
