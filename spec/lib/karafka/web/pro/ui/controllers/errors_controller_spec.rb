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
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when there are no errors" do
      before { get "errors" }

      it do
        expect(response).to be_ok
        expect(body).to include("This topic is empty and does not contain any data")
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context "when there are only few errors in one partition" do
      before do
        produce_many(errors_topic, Array.new(3) { error_report }, partition: 0)

        get "errors"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(3)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
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
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(6)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
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
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(25)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
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
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(25)
        expect(body).to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe "#partition" do
    context "when there are no errors" do
      before { get "errors/1" }

      it do
        expect(response).to be_ok
        expect(body).to include(no_errors)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
        expect(body).not_to include(pagination)
      end
    end

    context "when there are only few errors on a selected partition" do
      before do
        produce_many(errors_topic, Array.new(3) { error_report }, partition: 1)

        get "errors/1"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(3)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include("high: 3")
        expect(body).to include("low: 0")
        expect(body).to include(breadcrumbs)
      end
    end

    context "when there are enough errors for pagination to kick in" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(25)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include("high: 30")
        expect(body).to include("low: 0")
        expect(body).to include(breadcrumbs)
      end
    end

    context "when we want to visit second offset page with pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1?offset=0"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(25)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include("high: 30")
        expect(body).to include("low: 0")
        expect(body).to include(breadcrumbs)
      end
    end

    context "when we want to visit high offset page with pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1?offset=29"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError:").size).to eq(1)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include("high: 30")
        expect(body).to include("low: 0")
        expect(body).to include(breadcrumbs)
      end
    end

    context "when we want to visit page beyond pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report }, partition: 1)

        get "errors/1?offset=129"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(no_errors)
        expect(body.scan("StandardError:").size).to eq(0)
        expect(body).not_to include(pagination)
        expect(body).to include("high: 30")
        expect(body).not_to include(support_message)
        expect(body).to include("low: 0")
        expect(body).to include(breadcrumbs)
      end
    end
  end

  describe "#show" do
    context "when visiting offset that does not exist" do
      before { get "errors/0/123456" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when visiting error that does exist" do
      before do
        produce(errors_topic, error_report, partition: 0)

        get "errors/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include("shinra:1555833:4e8f7174ae53")
        expect(body.scan("StandardError").size).to eq(3)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include("This feature is available only")
      end
    end

    context "when visiting error offset with a transactional record in range" do
      before do
        produce(errors_topic, error_report, partition: 0, type: :transactional)

        get "errors/0/1"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include("shinra:1555833:4e8f7174ae53")
        expect(body).not_to include("StandardError")
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("The message has been removed")
        expect(body).not_to include(support_message)
        expect(body).not_to include("This feature is available only")
      end
    end

    context "when visiting offset on transactional above watermark" do
      before do
        produce(errors_topic, error_report, partition: 0, type: :transactional)

        get "errors/0/2"
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when viewing an error but having a different one in the offset" do
      before { get "errors/0/0?offset=1" }

      it "expect to redirect to the one from the offset" do
        expect(response.status).to eq(302)
        expect(response.headers["location"]).to include("errors/0/1")
      end
    end
  end
end
