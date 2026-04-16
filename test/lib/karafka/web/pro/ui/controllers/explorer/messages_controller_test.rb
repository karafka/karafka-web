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

  let(:topic) { create_topic }
  let(:target_topic) { create_topic }

  describe "#forward" do
    context "when we want to republish message from a non-existing topic" do
      before { get "explorer/messages/non-existing/0/1/forward" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:payload) { rand.to_s }

      before do
        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/forward"
      end

      it do
        assert(response.ok?)
        assert_body(topic)
        assert_body("message-republish-form")
        refute_body(pagination)
        refute_body(support_message)
      end
    end
  end

  describe "#republish" do
    context "when we want to republish message from a non-existing topic" do
      before { post "explorer/messages/non-existing/0/1/republish" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:republished) { wait_for_message(target_topic, 0, 0) }
      let(:payload) { rand.to_s }
      let(:target_partition) { 0 }
      let(:include_source_headers) { "on" }
      let(:params) do
        {
          target_topic: target_topic,
          target_partition: target_partition,
          include_source_headers: include_source_headers
        }
      end

      context "when we do not specify the target partition" do
        let(:target_partition) { "" }

        before do
          produce(topic, payload)
          post "explorer/messages/#{topic}/0/0/republish", params
        end

        it do
          assert_equal(302, response.status)
          # Taken from referer and referer is nil in specs
          assert_equal("/", response.location)
          assert_equal(payload, republished.raw_payload)
          assert_includes(republished.headers.keys, "source_topic")
          assert_includes(republished.headers.keys, "source_partition")
          assert_includes(republished.headers.keys, "source_offset")
        end
      end

      context "when we do not want source headers" do
        let(:include_source_headers) { false }

        before do
          produce(topic, payload)
          post "explorer/messages/#{topic}/0/0/republish", params
        end

        it do
          assert_equal(302, response.status)
          assert_equal("/", response.location)
          assert_equal(payload, republished.raw_payload)
          refute_includes(republished.headers.keys, "source_topic")
          refute_includes(republished.headers.keys, "source_partition")
          refute_includes(republished.headers.keys, "source_offset")
        end
      end

      context "when we specify target partition" do
        let(:target_partition) { 1 }
        let(:republished) { wait_for_message(target_topic, 1, 0) }
        let(:target_topic) { create_topic(partitions: 2) }

        before do
          produce(topic, payload)
          post "explorer/messages/#{topic}/0/0/republish", params
        end

        it do
          assert_equal(302, response.status)
          assert_equal("/", response.location)
          assert_equal(payload, republished.raw_payload)
          assert_includes(republished.headers.keys, "source_topic")
          assert_includes(republished.headers.keys, "source_partition")
          assert_includes(republished.headers.keys, "source_offset")
        end
      end
    end

    context "when message exists but republishing is off" do
      let(:payload) { rand.to_s }

      before do
        Karafka::Web.config.ui.policies.messages.stubs(:republish?).returns(false)

        produce(topic, payload)
        post "explorer/messages/#{topic}/0/0/republish"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end
  end

  describe "#download" do
    context "when we want to download message from a non-existing topic" do
      before { get "explorer/messages/non-existing/0/1/download" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.msg" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/download"
      end

      it do
        assert(response.ok?)
        assert_equal(expected_disposition, response.headers["content-disposition"])
        assert_equal("application/octet-stream", response.headers["content-type"])
        assert_equal(payload, response.body)
      end
    end

    context "when message exists but downloads are off" do
      let(:payload) { rand.to_s }

      before do
        Karafka::Web.config.ui.policies.messages.stubs(:download?).returns(false)

        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/download"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end
  end

  describe "#export" do
    context "when we want to export message from a non-existing topic" do
      before { get "explorer/messages/non-existing/0/1/export" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when message exists" do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.json" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/export"
      end

      it do
        assert(response.ok?)
        assert_equal(expected_disposition, response.headers["content-disposition"])
        assert_equal("application/octet-stream", response.headers["content-type"])
        assert_equal(payload, response.body)
      end
    end

    context "when message exists on a dynamic topic with custom deserializer" do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.json" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        topic_name = topic

        draw_routes do
          pattern(/#{topic_name}/) do
            active(false)
            deserializer(->(_message) { "1" })
          end
        end

        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/export"
      end

      it "expect to use custom deserializer" do
        assert(response.ok?)
        assert_equal(expected_disposition, response.headers["content-disposition"])
        assert_equal("application/octet-stream", response.headers["content-type"])
        assert_equal('"1"', response.body)
      end
    end

    context "when message exists but exports are off" do
      let(:payload) { rand.to_s }

      before do
        Karafka::Web.config.ui.policies.messages.stubs(:export?).returns(false)

        produce(topic, payload)
        get "explorer/messages/#{topic}/0/0/export"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end
  end
end
