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
  let(:estimator) { Karafka::Pro::Processing::ConsumerGroups::VirtualPartitions::Estimator }
  let(:run_params) { "concurrency=5&distribution=consistent&batch_size=100&sample_size=1000" }

  describe "#show" do
    let(:no_data_msg) { "Those partitions are empty and there is no data to estimate" }
    let(:many_partitions_msg) { "the estimate is computed based only" }
    let(:timeout_msg) { "The estimation did not finish within the time limit" }
    let(:key_grouping_msg) { "Messages are grouped by their key" }
    let(:share_groups_msg) { "It applies to consumer groups only, not to share groups" }

    context "when trying to estimate a non-existing topic" do
      before { get "topics/#{generate_topic_name}/virtual_partitions" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when the topic is internal and internal topics are hidden" do
      let(:internal_topic) { "__#{generate_topic_name}" }

      before do
        create_topic(topic_name: internal_topic)
        get "topics/#{internal_topic}/virtual_partitions"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when opening the page without params" do
      before do
        estimator.expects(:new).never
        produce_many(topic, Array.new(10, ""))
        get "topics/#{topic}/virtual_partitions"
      end

      it do
        assert_ok
        assert_body(breadcrumbs)
        assert_body(topic)
        assert_body('name="concurrency"')
        assert_body('name="sample_size"')
        assert_body(key_grouping_msg)
        assert_body(share_groups_msg)
        assert_body('custom-tab active"')
        assert_body("Virtual Partitions")
        refute_body("Verdict:")
        refute_body(no_data_msg)
      end
    end

    context "when estimating an empty topic" do
      before { get "topics/#{topic}/virtual_partitions?#{run_params}" }

      it do
        assert_ok
        assert_body(no_data_msg)
        refute_body("Verdict:")
      end
    end

    context "when estimating an empty topic with many partitions" do
      let(:partitions) { 100 }

      before { get "topics/#{topic}/virtual_partitions?#{run_params}" }

      it do
        assert_ok
        assert_body(pagination)
        assert_body(no_data_msg)
        assert_body(many_partitions_msg)
      end
    end

    context "when estimating a topic with keyed messages" do
      let(:partitions) { 2 }

      before do
        messages = Array.new(200) do |i|
          { topic: topic, payload: "", key: "key-#{i % 20}", partition: i % 2 }
        end

        PRODUCERS.regular.produce_many_sync(messages)

        get "topics/#{topic}/virtual_partitions?#{run_params}"
      end

      it do
        assert_ok
        assert_body("Verdict:")
        assert_body("Score:")
        assert_body("Active VPs:")
        assert_body("Messages: 200")
        assert_body("explorer/topics/#{topic}/0\"")
        assert_body("explorer/topics/#{topic}/1\"")
        assert_body("grouped by message key")
        assert_body(share_groups_msg)
        refute_body("key-1")
        refute_body(no_data_msg)
      end
    end

    context "when sorting the estimated partitions" do
      let(:partitions) { 2 }

      before do
        messages = Array.new(30) do |i|
          { topic: topic, payload: "", key: "key-#{i}", partition: (i < 10) ? 0 : 1 }
        end

        PRODUCERS.regular.produce_many_sync(messages)

        get "topics/#{topic}/virtual_partitions?#{run_params}&sort=messages+desc"
      end

      it do
        assert_ok
        assert_operator(
          body.index("explorer/topics/#{topic}/1\""),
          :<,
          body.index("explorer/topics/#{topic}/0\"")
        )
      end
    end

    context "when the estimation exceeds the time limit" do
      before do
        Karafka::Web.config.ui.topics.virtual_partitions.stubs(:timeout).returns(1)
        produce_many(topic, Array.new(100, ""))
        get "topics/#{topic}/virtual_partitions?#{run_params}"
      end

      it do
        assert_ok
        assert_body(timeout_msg)
        refute_body("Verdict:")
      end
    end

    {
      "concurrency=0" => "concurrency needs to be an integer",
      "concurrency=5abc" => "concurrency needs to be an integer",
      "distribution=unknown" => "distribution needs to be either consistent or balanced",
      "batch_size=0" => "batch size needs to be an integer",
      "sample_size=1234" => "sample size needs to be one of the allowed sample sizes"
    }.each do |invalid, message|
      context "when params are invalid (#{invalid})" do
        before do
          estimator.expects(:new).never
          params = run_params.split("&").to_h { |pair| pair.split("=") }
          key, value = invalid.split("=")
          params[key] = value

          get "topics/#{topic}/virtual_partitions?#{URI.encode_www_form(params)}"
        end

        it do
          assert_ok
          assert_body("Please Correct the Following Errors Before Continuing")
          assert_body(message)
          assert_body('name="concurrency"')
          refute_body("Verdict:")
        end
      end
    end
  end
end
