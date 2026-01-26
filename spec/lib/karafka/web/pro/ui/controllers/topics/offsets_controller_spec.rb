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

  describe "#show" do
    context "when trying to read offsets of a non-existing topic" do
      before { get "topics/#{generate_topic_name}/offsets" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when getting offsets of an existing empty topic" do
      before { get "topics/#{topic}/offsets" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('<table class="data-table">')
        expect(body.scan("<tr>").size).to eq(2)
      end
    end

    context "when getting offsets of an existing empty topic with multiple partitions" do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/offsets" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('<table class="data-table">')
        expect(body.scan("<tr>").size).to eq(26)
      end
    end

    context "when getting offsets of an existing topic with one partition and data" do
      before do
        produce_many(topic, Array.new(100, ""))
        get "topics/#{topic}/offsets"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('<table class="data-table">')
        expect(body).to include(topic)
        expect(body.scan("<tr>").size).to eq(2)
        expect(body.scan("<td>100</td>").size).to eq(2)
      end
    end

    context "when getting offsets of a topic with many partitions and data page 2" do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ""), partition: i) }

        get "topics/#{topic}/offsets?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('<table class="data-table">')
        expect(body).to include(topic)
        expect(body.scan("<tr>").size).to eq(26)
        expect(body.scan("<td>10</td>").size).to eq(50)
      end
    end
  end
end
