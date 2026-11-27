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

  let(:topic) { create_topic(partitions: 2) }
  let(:consumer_group_id) { SecureRandom.uuid }
  let(:policy) { Karafka::Web.config.ui.policies.consumer_groups }
  let(:path) { "health/consumer_groups/#{consumer_group_id}/topics/#{topic}/delete" }
  let(:committed) do
    Karafka::Admin::ConsumerGroups
      .read_lags_with_offsets({ consumer_group_id => [topic] })
      .dig(consumer_group_id, topic)
      .transform_values { |details| details[:offset] }
  end

  before do
    produce_many(topic, Array.new(30) { |i| i.to_s }, partition: 1)
    Karafka::Admin.seek_consumer_group(consumer_group_id, { topic => { 0 => 1, 1 => 2 } })
  end

  describe "#edit" do
    context "when deleting is not allowed by the default policy" do
      before { get path }

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end

    context "when deleting is allowed" do
      before { policy.stubs(:delete_offsets?).returns(true) }

      context "when the topic does not exist" do
        before { get "health/consumer_groups/#{consumer_group_id}/topics/non-existing/delete" }

        it do
          refute(response.ok?)
          assert_equal(404, response.status)
        end
      end

      context "when the topic is not in the routing" do
        before { get path }

        it "shows the offsets that would go and the confirmation form" do
          assert_ok
          assert_body("Offsets Deletion Warning")
          assert_body("<td>28</td>")
          assert_body(%(action="/#{path}"))
          assert_body(%(href="/health/consumer_groups/#{consumer_group_id}/topics"))
          assert_body("Delete Offsets")
          assert_body('data-live-poll="disabled"')
          assert_equal({ 0 => 1, 1 => 2 }, committed)
        end
      end
    end
  end

  describe "#delete" do
    context "when deleting is not allowed by the default policy" do
      before { delete path }

      it "does not delete the offsets" do
        assert_equal(403, response.status)
        assert_equal({ 0 => 1, 1 => 2 }, committed)
      end
    end

    context "when deleting is allowed" do
      before { policy.stubs(:delete_offsets?).returns(true) }

      context "when the consumer group is not subscribed to the topic" do
        before { delete path }

        it "deletes the offsets and redirects to the consumer group topics" do
          assert_equal(302, response.status)
          assert(response.location.end_with?("/health/consumer_groups/#{consumer_group_id}/topics"))
          assert_includes(flash[:success], "have been deleted")
          assert_equal({ 0 => -1, 1 => -1 }, committed)
        end
      end

      context "when the consumer group id has characters that are special in URLs and HTML" do
        let(:consumer_group_id) { "<b>a b/c?d#e%f</b>-#{SecureRandom.uuid}" }
        let(:encoded_id) { URI.encode_uri_component(consumer_group_id) }
        let(:path) { "health/consumer_groups/#{encoded_id}/topics/#{topic}/delete" }

        before do
          get path
          @edit_status = response.status

          delete path
        end

        it "deletes its offsets and escapes it in the flash" do
          assert_equal(200, @edit_status)
          assert_equal(302, response.status)
          assert(response.location.end_with?("/health/consumer_groups/#{encoded_id}/topics"))
          assert_includes(flash[:success], "&lt;b&gt;a b/c?d#e%f&lt;/b&gt;")
          refute_includes(flash[:success], "<b>a b")
          assert_equal({ 0 => -1, 1 => -1 }, committed)
        end
      end

      context "when the topic is inactive in the routing of the consumer group" do
        before do
          topic_name = topic
          group_name = consumer_group_id

          draw_routes do
            consumer_group group_name do
              topic topic_name do
                active(false)
              end
            end
          end

          get "health/cluster_lags"
          @listed_status = response.status
          @listed = body.include?(topic)

          delete path
        end

        it "is hidden from the cluster lags but its offsets can be deleted" do
          assert_equal(200, @listed_status)
          refute(@listed)
          assert_equal(302, response.status)
          assert_equal({ 0 => -1, 1 => -1 }, committed)
        end
      end

      context "when the consumer group id is not ASCII" do
        let(:consumer_group_id) { "zażółć gęślą-#{SecureRandom.uuid}" }
        let(:path) do
          "health/consumer_groups/#{URI.encode_uri_component(consumer_group_id)}" \
            "/topics/#{topic}/delete"
        end

        it "shows its offsets and deletes them" do
          get path

          assert_ok
          assert_body("<td>28</td>")

          delete path

          assert_equal(302, response.status)

          # Kafka reports the offsets under the group id it lists
          kafka_id = Karafka::Web::Pro::Ui::Models::Cluster::ConsumerGroup.kafka_id(consumer_group_id)
          offsets = Karafka::Admin::ConsumerGroups
            .read_lags_with_offsets({ kafka_id => [topic] })
            .dig(kafka_id, topic)

          assert_equal([-1, -1], offsets.values.map { |details| details[:offset] })
        end
      end

      context "when the consumer group is subscribed to the topic" do
        before do
          Karafka::Admin
            .stubs(:delete_consumer_group_offsets)
            .raises(Karafka::Errors::ConsumerGroupSubscribedToTopicError, consumer_group_id)

          delete path
        end

        it "explains why Kafka rejected it and keeps the offsets" do
          assert_ok
          assert_body("Consumer Group Subscribed To Topic")
          assert_body("has running consumers subscribed to topic")
          # A live poll refresh would replace the rejection with a fresh confirmation page
          assert_body('data-live-poll="disabled"')
          assert_equal({ 0 => 1, 1 => 2 }, committed)
        end
      end

      context "when it fails because of an rdkafka error" do
        before do
          Karafka::Admin
            .stubs(:delete_consumer_group_offsets)
            .raises(Rdkafka::RdkafkaError.new(Rdkafka::Bindings::RD_KAFKA_RESP_ERR__STATE))

          delete path
        end

        it "renders the error on the confirmation page" do
          assert_ok
          assert_body("Offsets Deletion Warning")
          assert_body("Please Correct the Following Errors Before Continuing")
          assert_body('data-live-poll="disabled"')
        end
      end
    end
  end
end
