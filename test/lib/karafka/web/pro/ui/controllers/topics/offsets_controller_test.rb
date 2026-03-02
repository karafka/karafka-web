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
    context "when trying to read offsets of a non-existing topic" do
      before { get "topics/#{generate_topic_name}/offsets" }

      it do
        refute_predicate(response, :ok?)
        assert_equal(404, status)
      end
    end

    context "when getting offsets of an existing empty topic" do
      before { get "topics/#{topic}/offsets" }

      it do
        assert_predicate(response, :ok?)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, topic)
        assert_includes(body, '<table class="data-table">')
        assert_equal(2, body.scan("<tr>").size)
      end
    end

    context "when getting offsets of an existing empty topic with multiple partitions" do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/offsets" }

      it do
        assert_predicate(response, :ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, topic)
        assert_includes(body, '<table class="data-table">')
        assert_equal(26, body.scan("<tr>").size)
      end
    end

    context "when getting offsets of an existing topic with one partition and data" do
      before do
        produce_many(topic, Array.new(100, ""))
        get "topics/#{topic}/offsets"
      end

      it do
        assert_predicate(response, :ok?)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, '<table class="data-table">')
        assert_includes(body, topic)
        assert_equal(2, body.scan("<tr>").size)
        assert_equal(2, body.scan("<td>100</td>").size)
      end
    end

    context "when getting offsets of a topic with many partitions and data page 2" do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ""), partition: i) }

        get "topics/#{topic}/offsets?page=2"
      end

      it do
        assert_predicate(response, :ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        refute_includes(body, support_message)
        assert_includes(body, '<table class="data-table">')
        assert_includes(body, topic)
        assert_equal(26, body.scan("<tr>").size)
        assert_equal(50, body.scan("<td>10</td>").size)
      end
    end
  end
end
