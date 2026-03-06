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
  let(:search_button) { 'title="Search in this topic"' }
  let(:partitions) { 1 }

  describe "#topic" do
    context "when we view topic without any messages" do
      before { get "scheduled_messages/explorer/topics/#{topic}" }

      it do
        assert(response.ok?)
        assert_includes(body, "This topic is empty and does not contain any data")
        assert_includes(body, breadcrumbs)
        refute_includes(body, "total: 1")
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        refute_includes(body, search_button)
      end
    end

    context "when we view topic with one tombstone message" do
      before do
        produce_many(topic, [nil], headers: { "schedule_source_type" => "tombstone" })
        get "scheduled_messages/explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, "total: 1")
        assert_includes(body, breadcrumbs)
        assert_includes(body, search_button)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when we view topic with messages with incorrect type" do
      before do
        produce_many(topic, [nil], headers: { "schedule_source_type" => "something else" })
        get "scheduled_messages/explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, "total: 1")
        assert_includes(body, breadcrumbs)
        assert_includes(body, search_button)
        assert_includes(body, "This offset does not contain any recognized data type.")
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when we view topic with one cancel message" do
      before do
        produce_many(topic, [nil], headers: { "schedule_source_type" => "cancel" })
        get "scheduled_messages/explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, "total: 1")
        assert_includes(body, "cancel")
        assert_includes(body, breadcrumbs)
        assert_includes(body, search_button)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when we view topic with one message with broken key" do
      let(:key_deserializer) { ->(_headers) { raise } }

      before do
        topic_name = topic
        deserializer = key_deserializer

        draw_routes do
          topic topic_name do
            active(false)
            # This will crash key deserialization, since it requires json
            deserializers(key: deserializer)
          end
        end

        produce_many(topic, [nil], key: "{", headers: { "schedule_source_type" => "schedule" })
        get "scheduled_messages/explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, "total: 1")
        assert_includes(body, breadcrumbs)
        assert_includes(body, "[Deserialization Failed]")
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when we view first page from a topic with one partition with data" do
      before do
        produce_many(topic, Array.new(30, "1"), headers: { "schedule_source_type" => "schedule" })
        get "scheduled_messages/explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, '<span class="badge  badge-primary">schedule</span>')
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        assert_includes(body, "#{topic}/0/5")
        refute_includes(body, support_message)
      end
    end

    context "when we view first page from a topic with one partition with transactional data" do
      before do
        produce_many(
          topic,
          Array.new(30, "1"),
          type: :transactional,
          headers: { "schedule_source_type" => "schedule" }
        )
        get "scheduled_messages/explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, pagination)
        assert_includes(body, "#{topic}/0/6")
        assert_includes(body, "#{topic}/0/29")
        assert_includes(body, compacted_or_transactional_offset)
        assert_includes(body, search_button)
        refute_includes(body, "#{topic}/0/30")
        refute_includes(body, "#{topic}/0/4")
        refute_includes(body, support_message)
      end
    end
  end

  describe "#partition" do
    let(:no_data) { "This partition is empty and does not contain any data" }

    context "when given partition does not exist" do
      before { get "scheduled_messages/explorer/topics/#{topic}/1" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when no data in the given partition" do
      before { get "scheduled_messages/explorer/topics/#{topic}/0" }

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, no_data)
        refute_includes(body, "high: 0")
        refute_includes(body, "low: 0")
        refute_includes(body, "Watermark offsets")
        refute_includes(body, pagination)
        refute_includes(body, support_message)
        refute_includes(body, search_button)
      end
    end

    context "when single result in a given partition is present" do
      before do
        produce(topic, "1")
        get "scheduled_messages/explorer/topics/#{topic}/0"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Watermark offsets")
        assert_includes(body, "high: 1")
        assert_includes(body, "low: 0")
        assert_includes(body, search_button)
        refute_includes(body, no_data)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when only single transactional result in a given partition is present" do
      before do
        produce(topic, "1", type: :transactional)
        get "scheduled_messages/explorer/topics/#{topic}/0"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Watermark offsets")
        assert_includes(body, "high: 2")
        assert_includes(body, "low: 0")
        refute_includes(body, no_data)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when compacted results are present in a partition" do
      before do
        produce(topic, "1")

        allow(Karafka::Web::Ui::Models::Message)
          .to receive(:offset_page)
          .and_return([false, [[0, 0]], false])

        get "scheduled_messages/explorer/topics/#{topic}/0"
      end

      it do
        assert(response.ok?)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Watermark offsets")
        assert_includes(body, "high: 1")
        assert_includes(body, "low: 0")
        refute_includes(body, no_data)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when there are multiple pages" do
      before { produce_many(topic, Array.new(100, "1")) }

      context "when we view the from the highest available offset" do
        before { get "scheduled_messages/explorer/topics/#{topic}/0?offset=99" }

        it do
          assert(response.ok?)
          assert_includes(body, breadcrumbs)
          assert_includes(body, "Watermark offsets")
          assert_includes(body, "high: 100")
          assert_includes(body, "low: 0")
          assert_includes(body, pagination)
          assert_includes(body, "/explorer/topics/#{topic}/0/99")
          refute_includes(body, "/explorer/topics/#{topic}/0/98")
          refute_includes(body, "/explorer/topics/#{topic}/0/100")
          refute_includes(body, no_data)
          refute_includes(body, support_message)
        end
      end

      context "when we view the from the highest full page" do
        before { get "scheduled_messages/explorer/topics/#{topic}/0?offset=75" }

        it do
          assert(response.ok?)
          assert_includes(body, breadcrumbs)
          assert_includes(body, "Watermark offsets")
          assert_includes(body, "high: 100")
          assert_includes(body, "low: 0")
          assert_includes(body, pagination)
          assert_includes(body, "/explorer/topics/#{topic}/0/99")
          assert_includes(body, "/explorer/topics/#{topic}/0/75")
          refute_includes(body, "/explorer/topics/#{topic}/0/100")
          refute_includes(body, "/explorer/topics/#{topic}/0/74")
          refute_includes(body, no_data)
          refute_includes(body, support_message)
          # 26 because 25 for details + one for breadcrumbs
          assert_equal(26, body.scan("href=\"/explorer/topics/#{topic}/0/").count)
        end
      end

      context "when we view the lowest offsets" do
        before { get "scheduled_messages/explorer/topics/#{topic}/0?offset=0" }

        it do
          assert(response.ok?)
          assert_includes(body, breadcrumbs)
          assert_includes(body, "Watermark offsets")
          assert_includes(body, "high: 100")
          assert_includes(body, "low: 0")
          assert_includes(body, pagination)
          assert_includes(body, "/explorer/topics/#{topic}/0/0")
          assert_includes(body, "/explorer/topics/#{topic}/0/24")
          refute_includes(body, "/explorer/topics/#{topic}/0/99")
          refute_includes(body, "/explorer/topics/#{topic}/0/75")
          refute_includes(body, "/explorer/topics/#{topic}/0/25")
          refute_includes(body, no_data)
          refute_includes(body, support_message)
          # 26 because 25 for details + one for breadcrumbs
          assert_equal(26, body.scan("href=\"/explorer/topics/#{topic}/0/").count)
        end
      end

      context "when we go way above the existing offsets" do
        before { get "scheduled_messages/explorer/topics/#{topic}/0?offset=1000" }

        it do
          assert(response.ok?)
          assert_includes(body, breadcrumbs)
          assert_includes(body, "This page does not contain any data")
          refute_includes(body, "Watermark offsets")
          refute_includes(body, "high: 100")
          refute_includes(body, "low: 0")
          refute_includes(body, pagination)
          refute_includes(body, "/explorer/topics/#{topic}/0/99")
          refute_includes(body, "/explorer/topics/#{topic}/0/100")
          refute_includes(body, support_message)
        end
      end
    end
  end

  describe "#closest" do
    let(:now_in_ms) { (Time.now.to_f * 1_000).round }

    context "when requested topic does not exist with date" do
      before { get "scheduled_messages/explorer/topic/100/closest/2023-10-10/12:12:12" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested topic does not exist with timestamp" do
      before { get "scheduled_messages/explorer/topic/100/closest/0" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested date is not a valid date" do
      before { get "scheduled_messages/explorer/topic/100/closest/2023-13-10/27:12:12" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested date is not a valid timestamp" do
      before { get "scheduled_messages/explorer/topic/100/closest/03142341231" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when we have only one older message with date" do
      before do
        produce(topic, "1")
        get "scheduled_messages/explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have only one older message with timestamp" do
      before do
        produce(topic, "1")
        get "scheduled_messages/explorer/topics/#{topic}/0/closest/#{now_in_ms + 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier time" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "scheduled_messages/explorer/topics/#{topic}/0/closest/2000-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier timestamp" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "scheduled_messages/explorer/topics/#{topic}/0/closest/#{now_in_ms - 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier time on a higher partition" do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, "1"), partition: 1)
        get "scheduled_messages/explorer/topics/#{topic}/1/closest/2000-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/1?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier timestamp on a higher partition" do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, "1"), partition: 1)
        get "scheduled_messages/explorer/topics/#{topic}/1/closest/#{now_in_ms - 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/1?offset=0", response.location)
      end
    end

    context "when we have many messages and we request later time" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "scheduled_messages/explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0?offset=99", response.location)
      end
    end

    context "when we have many messages and we request later timestamp" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "scheduled_messages/explorer/topics/#{topic}/0/closest/#{now_in_ms + 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0?offset=99", response.location)
      end
    end

    context "when we request a time on an empty topic partition" do
      before { get "scheduled_messages/explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12" }

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0", response.location)
      end
    end

    context "when we request a timestamp on an empty topic partition" do
      before { get "scheduled_messages/explorer/topics/#{topic}/0/closest/#{now_in_ms}" }

      it do
        assert_equal(302, response.status)
        assert_equal("/scheduled_messages/explorer/topics/#{topic}/0", response.location)
      end
    end
  end
end
