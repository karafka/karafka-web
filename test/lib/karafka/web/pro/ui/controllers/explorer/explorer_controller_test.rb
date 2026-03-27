# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:removed_or_compacted) { "This offset does not contain any data." }
  let(:internal_topic) { "__#{generate_topic_name}" }
  let(:search_button) { 'title="Search in this topic"' }

  describe "#index" do
    before do
      create_topic(topic_name: internal_topic)
      get "explorer/topics"
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
        Karafka::Web::Ui::Models::ClusterInfo.stubs(:topics).returns([])
        get "explorer/topics"
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

        get "explorer/topics"
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

  describe "#topic" do
    context "when we view topic without any messages" do
      before { get "explorer/topics/#{topic}" }

      it do
        assert(response.ok?)
        assert_body("This topic is empty and does not contain any data")
        assert_body(breadcrumbs)
        refute_body("total: 1")
        refute_body(pagination)
        refute_body(support_message)
        refute_body(search_button)
      end
    end

    context "when we view topic with one nil message" do
      before do
        produce_many(topic, [nil])
        get "explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_body("total: 1")
        assert_body(breadcrumbs)
        assert_body(search_button)
        refute_body(pagination)
        refute_body(support_message)
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

        produce_many(topic, [nil], key: "{")
        get "explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_body("total: 1")
        assert_body(breadcrumbs)
        assert_body("[Deserialization Failed]")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when we view first page from a topic with one partition with data" do
      before do
        produce_many(topic, Array.new(30, "1"))
        get "explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(pagination)
        assert_body("#{topic}/0/5")
        assert_body("#{topic}/0/29")
        refute_body("#{topic}/0/30")
        refute_body("#{topic}/0/4")
        refute_body(support_message)
      end
    end

    context "when we view first page from a topic with one partition with transactional data" do
      before do
        produce_many(topic, Array.new(30, "1"), type: :transactional)
        get "explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(pagination)
        assert_body("#{topic}/0/6")
        assert_body("#{topic}/0/29")
        assert_body(compacted_or_transactional_offset)
        assert_body(search_button)
        refute_body("#{topic}/0/30")
        refute_body("#{topic}/0/4")
        refute_body(support_message)
      end
    end

    context "when we view last page from a topic with one partition with data" do
      before do
        produce_many(topic, Array.new(30, "1"))
        get "explorer/topics/#{topic}?page=2"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(pagination)
        assert_body("#{topic}/0/4")
        refute_body("#{topic}/0/30")
        refute_body("#{topic}/0/5")
        refute_body("#{topic}/0/29")
        refute_body(support_message)
      end
    end

    context "when we view first page from a topic with many partitions" do
      let(:partitions) { 5 }

      before do
        partitions.times { |i| produce_many(topic, Array.new(30, "1"), partition: i) }
        get "explorer/topics/#{topic}"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(pagination)

        partitions.times do |i|
          assert_body("#{topic}/#{i}/29")
          assert_body("#{topic}/#{i}/28")
          assert_body("#{topic}/#{i}/27")
          assert_body("#{topic}/#{i}/26")
          assert_body("#{topic}/#{i}/25")
          refute_body("#{topic}/#{i}/24")
          refute_body("#{topic}/#{i}/30")
        end

        refute_body(support_message)
      end
    end

    context "when we view last page from a topic with many partitions" do
      let(:partitions) { 5 }

      before do
        partitions.times { |i| produce_many(topic, Array.new(30, "1"), partition: i) }
        get "explorer/topics/#{topic}?page=6"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(pagination)

        partitions.times do |i|
          assert_body("#{topic}/#{i}/4")
          assert_body("#{topic}/#{i}/3")
          assert_body("#{topic}/#{i}/2")
          assert_body("#{topic}/#{i}/1")
          assert_body("#{topic}/#{i}/0")
          refute_body("#{topic}/#{i}/5")
          refute_body("#{topic}/#{i}/6")
        end

        refute_body(support_message)
      end
    end

    context "when we request a page above available elements" do
      before do
        produce_many(topic, Array.new(30, "1"))
        get "explorer/topics/#{topic}?page=100"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(pagination)
        assert_body(no_meaningful_results)
        refute_body(support_message)
      end
    end
  end

  describe "#partition" do
    let(:no_data) { "This partition is empty and does not contain any data" }

    context "when given partition does not exist" do
      before { get "explorer/topics/#{topic}/1" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when given partition is more than 32bit C int" do
      before { get "explorer/topics/#{topic}/2147483648" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when no data in the given partition" do
      before { get "explorer/topics/#{topic}/0" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(no_data)
        refute_body("high: 0")
        refute_body("low: 0")
        refute_body("Watermark offsets")
        refute_body(pagination)
        refute_body(support_message)
        refute_body(search_button)
      end
    end

    context "when single result in a given partition is present" do
      before do
        produce(topic, "1")
        get "explorer/topics/#{topic}/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Watermark offsets")
        assert_body("high: 1")
        assert_body("low: 0")
        assert_body(search_button)
        refute_body(no_data)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when only single transactional result in a given partition is present" do
      before do
        produce(topic, "1", type: :transactional)
        get "explorer/topics/#{topic}/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Watermark offsets")
        assert_body("high: 2")
        assert_body("low: 0")
        refute_body(no_data)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when compacted results are present in a partition" do
      before do
        produce(topic, "1")

        Karafka::Web::Ui::Models::Message.stubs(:offset_page).returns([false, [[0, 0]], false])

        get "explorer/topics/#{topic}/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Watermark offsets")
        assert_body("high: 1")
        assert_body("low: 0")
        assert_body(removed_or_compacted)
        refute_body(no_data)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when there are multiple pages" do
      before { produce_many(topic, Array.new(100, "1")) }

      context "when we view the from the highest available offset" do
        before { get "explorer/topics/#{topic}/0?offset=99" }

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          assert_body("Watermark offsets")
          assert_body("high: 100")
          assert_body("low: 0")
          assert_body(pagination)
          assert_body("/explorer/topics/#{topic}/0/99")
          refute_body("/explorer/topics/#{topic}/0/98")
          refute_body("/explorer/topics/#{topic}/0/100")
          refute_body(no_data)
          refute_body(support_message)
        end
      end

      context "when we view the from the highest full page" do
        before { get "explorer/topics/#{topic}/0?offset=75" }

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          assert_body("Watermark offsets")
          assert_body("high: 100")
          assert_body("low: 0")
          assert_body(pagination)
          assert_body("/explorer/topics/#{topic}/0/99")
          assert_body("/explorer/topics/#{topic}/0/75")
          refute_body("/explorer/topics/#{topic}/0/100")
          refute_body("/explorer/topics/#{topic}/0/74")
          refute_body(no_data)
          refute_body(support_message)
          # 26 because 25 for details + one for breadcrumbs
          assert_equal(26, body.scan("href=\"/explorer/topics/#{topic}/0/").count)
        end
      end

      context "when we view the lowest offsets" do
        before { get "explorer/topics/#{topic}/0?offset=0" }

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          assert_body("Watermark offsets")
          assert_body("high: 100")
          assert_body("low: 0")
          assert_body(pagination)
          assert_body("/explorer/topics/#{topic}/0/0")
          assert_body("/explorer/topics/#{topic}/0/24")
          refute_body("/explorer/topics/#{topic}/0/99")
          refute_body("/explorer/topics/#{topic}/0/75")
          refute_body("/explorer/topics/#{topic}/0/25")
          refute_body(no_data)
          refute_body(support_message)
          # 26 because 25 for details + one for breadcrumbs
          assert_equal(26, body.scan("href=\"/explorer/topics/#{topic}/0/").count)
        end
      end

      context "when we go way above the existing offsets" do
        before { get "explorer/topics/#{topic}/0?offset=1000" }

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          assert_body("This page does not contain any data")
          refute_body("Watermark offsets")
          refute_body("high: 100")
          refute_body("low: 0")
          refute_body(pagination)
          refute_body("/explorer/topics/#{topic}/0/99")
          refute_body("/explorer/topics/#{topic}/0/100")
          refute_body(support_message)
        end
      end
    end
  end

  describe "#show" do
    let(:cannot_deserialize) { "We could not deserialize the <strong>payload</strong> due" }

    context "when requested offset does not exist" do
      before { get "explorer/topics/#{topic}/0/0" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested partition does not exist" do
      before { get "explorer/topics/#{topic}/1/0" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested message exists and can be deserialized" do
      before do
        produce(topic, { test: "me" }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("Export as JSON")
        assert_body("Download raw")
        assert_body("Republish")
        refute_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists and has array headers" do
      before do
        produce(
          topic,
          { test: "me" }.to_json,
          headers: {
            "super1" => "tadam1",
            "super2" => "tadam2"
          }
        )
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("Export as JSON")
        assert_body("Download raw")
        assert_body("Republish")
        assert_body("super1")
        assert_body("super2")
        assert_body("tadam1")
        assert_body("tadam2")
        refute_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists but should not be republishable" do
      before do
        Karafka::Web.config.ui.policies.messages.stubs(:republish?).returns(false)

        produce(topic, { test: "me" }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("Export as JSON")
        assert_body("Download raw")
        refute_body("Republish")
        refute_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists, can be deserialized and comes from a pattern" do
      before do
        topic_name = topic
        draw_routes do
          pattern(/#{topic_name}/) do
            active(false)
            deserializer(->(_message) { "16d6d5c5-d8a8-45fc-ae1d-34e134772b98" })
          end
        end

        produce(topic, { test: "me" }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("Export as JSON")
        assert_body("Download raw")
        assert_body("16d6d5c5-d8a8-45fc-ae1d-34e134772b98")
        refute_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists, can be deserialized and raw download is off" do
      before do
        Karafka::Web.config.ui.policies.messages.stubs(:download?).returns(false)

        produce(topic, { test: "me" }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("Export as JSON")
        refute_body("Download raw")
        refute_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists, can be deserialized but export is off" do
      before do
        Karafka::Web.config.ui.policies.messages.stubs(:export?).returns(false)

        produce(topic, { test: "me" }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("Download raw")
        refute_body("Export as JSON")
        refute_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists but is nil" do
      before do
        produce(topic, nil)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists but is a system entry" do
      before do
        produce(topic, nil, type: :transactional)
        get "explorer/topics/#{topic}/0/1"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("The message has been removed through")
        assert_body(pagination)
        refute_body('<code class="json')
        refute_body("Metadata")
        refute_body(support_message)
      end
    end

    context "when requested message exists but is too big to be presented" do
      before do
        topic_name = topic
        draw_routes do
          topic topic_name do
            active(false)
            deserializers(payload: Karafka::Web::Deserializer.new)
          end
        end

        data = Fixtures.consumers_metrics_json("current")
        # More than 512KB limit but less than 1MB default Kafka topic limit
        data[:too_much] = "a" * 1024 * 800

        produce(
          topic,
          data.to_json,
          headers: { "zlib" => "1" }
        )
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body('<code class="json')
        assert_body("Metadata")
        assert_body("Message payloads larger than")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when trace_object_allocations_start is not available" do
      before do
        ObjectSpace.stubs(:respond_to?).with(:trace_object_allocations_start).returns(false)

        produce(topic, "1")
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        refute_body(pagination)
        refute_body(support_message)
        assert_body("Not Available")
      end
    end

    context "when message exists but cannot be deserialized" do
      before do
        produce(topic, "{1=")
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Metadata")
        assert_body('<code class="json')
        assert_body(cannot_deserialize)
        refute_body(pagination)
        refute_body(support_message)
        refute_body("Export as JSON")
      end
    end

    context "when key exists but cannot be deserialized" do
      let(:cannot_deserialize) { "We could not deserialize the <strong>key</strong> due" }

      before do
        topic_name = topic
        draw_routes do
          topic topic_name do
            active(false)
            # This will crash key deserialization, since it requires json
            deserializers(key: Karafka::Web::Deserializer.new)
          end
        end

        produce(topic, "{}", key: "{")
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body("Metadata")
        assert_body('<code class="json')
        assert_body("")
        assert_body("Export as JSON")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when viewing a message but having a different one in the offset" do
      before { get "explorer/topics/#{topic}/0/0?offset=1" }

      it "expect to redirect to the one from the offset" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "explorer/topics/#{topic}/0/1")
      end
    end

    context "when requested message exists and is of 1 byte" do
      before do
        produce(topic, rand(256).chr)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("0.001 KB")
        refute_body(pagination)
        refute_body(support_message)
      end
    end

    context "when requested message exists and is of 100 byte" do
      before do
        produce(topic, SecureRandom.random_bytes(100))
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body('<code class="json')
        assert_body("Metadata")
        assert_body("0.0977 KB")
        refute_body(pagination)
        refute_body(support_message)
      end
    end
  end

  describe "#recent" do
    let(:payload1) { SecureRandom.uuid }
    let(:payload2) { SecureRandom.uuid }

    context "when getting recent for the whole topic" do
      let(:partitions) { 2 }

      context "when recent is on the first partition" do
        before do
          produce(topic, payload1, partition: 1)
          produce(topic, payload2, partition: 0)
          get "explorer/topics/#{topic}/recent"
        end

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          assert_body(payload2)
          assert_body(topic)
          refute_body(payload1)
          refute_body(pagination)
          refute_body(support_message)
        end
      end

      context "when recent is on another partition" do
        before do
          produce(topic, payload1, partition: 0)
          sleep(0.1)
          produce(topic, payload2, partition: 1)
          get "explorer/topics/#{topic}/recent"
        end

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          assert_body(payload2)
          assert_body(topic)
          refute_body(payload1)
          refute_body(pagination)
          refute_body(support_message)
        end
      end
    end

    context "when getting recent for the partition" do
      before do
        produce(topic, payload1, partition: 0)
        get "explorer/topics/#{topic}/0/recent"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        assert_body(payload1)
        assert_body(topic)
        refute_body(payload2)
        refute_body(pagination)
        refute_body(support_message)
      end
    end
  end

  describe "#surrounding" do
    context "when given offset is lower than that exists" do
      before { get "explorer/topics/#{topic}/0/0/surrounding" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when given offset is higher than that exists" do
      before { get "explorer/topics/#{topic}/0/100/surrounding" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when given message is the only one" do
      before do
        produce(topic, { test: "me" }.to_json)
        get "explorer/topics/#{topic}/0/0/surrounding"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when given message is the newest one" do
      before do
        produce_many(topic, Array.new(50, "1"))
        get "explorer/topics/#{topic}/0/49/surrounding"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=25", response.location)
      end
    end

    context "when given message is first out of many" do
      before do
        produce_many(topic, Array.new(50, "1"))
        get "explorer/topics/#{topic}/0/0/surrounding"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when given message is a middle one out of many" do
      before do
        produce_many(topic, Array.new(50, "1"))
        get "explorer/topics/#{topic}/0/25/surrounding"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=12", response.location)
      end
    end
  end

  describe "#closest" do
    let(:now_in_ms) { (Time.now.to_f * 1_000).round }

    context "when requested topic does not exist with date" do
      before { get "explorer/topics/topic/100/closest/2023-10-10/12:12:12" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested topic does not exist with timestamp" do
      before { get "explorer/topics/topic/100/closest/0" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested date is not a valid date" do
      before { get "explorer/topics/topic/100/closest/2023-13-10/27:12:12" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when requested date is not a valid timestamp" do
      before { get "explorer/topics/topic/100/closest/03142341231" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when we have only one older message with date" do
      before do
        produce(topic, "1")
        get "explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have a timestamp without seconds" do
      before do
        produce(topic, "1")
        get "explorer/topics/#{topic}/0/closest/2025-04-18/12:37"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have only one older message with timestamp" do
      before do
        produce(topic, "1")
        get "explorer/topics/#{topic}/0/closest/#{now_in_ms + 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier time" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "explorer/topics/#{topic}/0/closest/2000-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier timestamp" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "explorer/topics/#{topic}/0/closest/#{now_in_ms - 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier time on a higher partition" do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, "1"), partition: 1)
        get "explorer/topics/#{topic}/1/closest/2000-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/1?offset=0", response.location)
      end
    end

    context "when we have many messages and we request earlier timestamp on a higher partition" do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, "1"), partition: 1)
        get "explorer/topics/#{topic}/1/closest/#{now_in_ms - 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/1?offset=0", response.location)
      end
    end

    context "when we have many messages and we request later time" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=99", response.location)
      end
    end

    context "when we have many messages and we request later timestamp" do
      before do
        produce_many(topic, Array.new(100, "1"))
        get "explorer/topics/#{topic}/0/closest/#{now_in_ms + 100_000}"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0?offset=99", response.location)
      end
    end

    context "when we request a time on an empty topic partition" do
      before { get "explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12" }

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0", response.location)
      end
    end

    context "when we request a timestamp on an empty topic partition" do
      before { get "explorer/topics/#{topic}/0/closest/#{now_in_ms}" }

      it do
        assert_equal(302, response.status)
        assert_equal("/explorer/topics/#{topic}/0", response.location)
      end
    end
  end
end
