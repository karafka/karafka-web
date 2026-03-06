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

  let(:errors_topic) { create_topic(partitions: partitions) }
  let(:partitions) { 2 }
  let(:error_report) { Fixtures.errors_file }
  let(:no_errors) { "There are no errors in this errors topic partition" }

  before { topics_config.errors.name = errors_topic }

  describe "#index" do
    context "when needed topics are missing" do
      let(:errors_topic) { generate_topic_name }

      before { get "errors" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are no errors" do
      before { get "errors" }

      it do
        assert(response.ok?)
        assert_includes(body, "This topic is empty and does not contain any data")
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when there are only few errors in one partition" do
      before do
        produce_many(errors_topic, Array.new(3) { error_report }, partition: 0)

        get "errors"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError:").size)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, breadcrumbs)
      end
    end

    context "when there are only few errors in many partitions" do
      before do
        partitions.times do |i|
          produce_many(errors_topic, Array.new(3) { error_report }, partition: i)
        end

        get "errors"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(6, body.scan("StandardError:").size)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, breadcrumbs)
      end
    end

    context "when there are enough errors for pagination to kick in" do
      before do
        partitions.times do |i|
          produce_many(errors_topic, Array.new(30) { error_report }, partition: i)
        end

        get "errors"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, breadcrumbs)
      end
    end

    context "when we want to visit second offset page with pagination" do
      before do
        partitions.times do |i|
          produce_many(errors_topic, Array.new(30) { error_report }, partition: i)
        end

        get "errors?page=1"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_includes(body, pagination)
        assert_includes(body, breadcrumbs)
        refute_includes(body, support_message)
      end
    end
  end

  describe "#partition" do
    context "when there are no errors" do
      before { get "errors/1" }

      it do
        assert(response.ok?)
        assert_includes(body, no_errors)
        assert_includes(body, breadcrumbs)
        refute_includes(body, support_message)
        refute_includes(body, pagination)
      end
    end

    context "when there are only few errors on a selected partition" do
      before do
        produce_many(errors_topic, Array.new(3) { error_report }, partition: 1)

        get "errors/1"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError:").size)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "high: 3")
        assert_includes(body, "low: 0")
        assert_includes(body, breadcrumbs)
      end
    end

    context "when there are enough errors for pagination to kick in" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "high: 30")
        assert_includes(body, "low: 0")
        assert_includes(body, breadcrumbs)
      end
    end

    context "when we want to visit second offset page with pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1?offset=0"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "high: 30")
        assert_includes(body, "low: 0")
        assert_includes(body, breadcrumbs)
      end
    end

    context "when we want to visit high offset page with pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1?offset=29"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(1, body.scan("StandardError:").size)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, "high: 30")
        assert_includes(body, "low: 0")
        assert_includes(body, breadcrumbs)
      end
    end

    context "when we want to visit page beyond pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1?offset=129"
      end

      it do
        assert(response.ok?)
        refute_includes(body, no_errors)
        assert_equal(0, body.scan("StandardError:").size)
        refute_includes(body, pagination)
        assert_includes(body, "high: 30")
        refute_includes(body, support_message)
        assert_includes(body, "low: 0")
        assert_includes(body, breadcrumbs)
      end
    end
  end

  describe "#show" do
    context "when visiting offset that does not exist" do
      before { get "errors/0/123456" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when visiting error that does exist" do
      before do
        produce(errors_topic, error_report, partition: 0)

        get "errors/0/0"
      end

      it do
        assert(response.ok?)
        assert_includes(body, "shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError").size)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        refute_includes(body, "This feature is available only")
      end
    end

    context "when visiting error offset with a transactional record in range" do
      before do
        produce(errors_topic, error_report, partition: 0, type: :transactional)

        get "errors/0/1"
      end

      it do
        assert(response.ok?)
        refute_includes(body, "shinra:1555833:4e8f7174ae53")
        refute_includes(body, "StandardError")
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        assert_includes(body, "The message has been removed")
        refute_includes(body, support_message)
        refute_includes(body, "This feature is available only")
      end
    end

    context "when visiting offset on transactional above watermark" do
      before do
        produce(errors_topic, error_report, partition: 0, type: :transactional)

        get "errors/0/2"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when viewing an error but having a different one in the offset" do
      before { get "errors/0/0?offset=1" }

      it "expect to redirect to the one from the offset" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "errors/0/1")
      end
    end
  end
end
