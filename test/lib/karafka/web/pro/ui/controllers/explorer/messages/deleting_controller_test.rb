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
  let(:policy) { Karafka::Web.config.ui.policies.messages }
  let(:low_watermark) { Karafka::Admin.read_watermark_offsets(topic, 0).first }
  let(:audit_line) { ->(line) { line.to_s.start_with?("Web UI deleted") } }

  describe "#confirm" do
    context "when deleting is not allowed by the default policy" do
      before do
        produce_many(topic, %w[1 2 3])
        get "explorer/messages/#{topic}/0/2/delete"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end

    context "when deleting is allowed" do
      before { policy.stubs(:delete_records?).returns(true) }

      context "when topic does not exist" do
        before { get "explorer/messages/non-existing/0/1/delete" }

        it do
          refute(response.ok?)
          assert_equal(404, response.status)
        end
      end

      context "when partition does not exist" do
        before { get "explorer/messages/#{topic}/1/0/delete" }

        it do
          refute(response.ok?)
          assert_equal(404, response.status)
        end
      end

      context "when offset is above the high watermark" do
        before do
          produce_many(topic, %w[1 2 3])
          get "explorer/messages/#{topic}/0/4/delete"
        end

        it do
          refute(response.ok?)
          assert_equal(404, response.status)
        end
      end

      context "when there are messages below the offset" do
        before do
          produce_many(topic, %w[1 2 3])
          get "explorer/messages/#{topic}/0/2/delete"
        end

        it "shows the offsets range that would go and the confirmation form" do
          assert_ok
          assert_body("Messages Deletion Warning")
          assert_body("all messages in offsets")
          assert_body('<span class="font-bold ml-1">0</span>')
          assert_body('<span class="font-bold ml-1">1</span>')
          assert_body('<span class="font-bold ml-1">2</span>')
          assert_body("explorer/messages/#{topic}/0/2/delete")
          assert_body("Delete Messages")
        end
      end

      context "when there are no messages below the offset" do
        before do
          produce_many(topic, %w[1 2 3])
          get "explorer/messages/#{topic}/0/0/delete"
        end

        it "does not offer the deletion" do
          assert_ok
          assert_body("There are no messages below offset")
          refute_body("Delete Messages")
        end
      end

      context "when the low watermark was already moved" do
        before do
          produce_many(topic, %w[1 2 3 4])
          Karafka::Admin.delete_records(topic => [{ partition: 0, offset: 1 }])
        end

        context "when there are messages between the low watermark and the offset" do
          before { get "explorer/messages/#{topic}/0/3/delete" }

          it "counts only the offsets above the low watermark" do
            assert_ok
            assert_match(
              %r{
                offsets\s+<span[^>]*>1</span>\s+
                to\s+<span[^>]*>2</span>\s+
                \(up\ to\s+<span[^>]*>2</span>\s+messages\)
              }x,
              response.body
            )
            assert_body("Delete Messages")
          end
        end

        context "when the offset is below the low watermark" do
          before { get "explorer/messages/#{topic}/0/0/delete" }

          it "does not offer the deletion" do
            assert_ok
            assert_body("There are no messages below offset")
            refute_body("Delete Messages")
          end
        end
      end
    end
  end

  describe "#delete" do
    before { Karafka.logger.stubs(:info) }

    context "when deleting is not allowed by the default policy" do
      before do
        produce_many(topic, %w[1 2 3])
        Karafka.logger.expects(:info).with(&audit_line).never
        delete "explorer/messages/#{topic}/0/2/delete"
      end

      it "does not delete anything" do
        assert_equal(403, response.status)
        assert_equal(0, low_watermark)
      end
    end

    context "when deleting is allowed" do
      before { policy.stubs(:delete_records?).returns(true) }

      context "when topic does not exist" do
        before { delete "explorer/messages/non-existing/0/1/delete" }

        it do
          refute(response.ok?)
          assert_equal(404, response.status)
        end
      end

      context "when there are messages below the offset" do
        before do
          produce_many(topic, %w[1 2 3])

          Karafka.logger
            .expects(:info)
            .with("Web UI deleted offsets 0 to 1 (up to 2 messages) from #{topic}#0")
            .once

          delete "explorer/messages/#{topic}/0/2/delete"
        end

        it "deletes them, writes the audit line and redirects to the partition" do
          assert_equal(302, response.status)
          assert_equal("/explorer/topics/#{topic}/0", response.location)
          assert_includes(
            flash[:success],
            "Messages in offsets 0 to 1 (up to 2 messages) have been deleted from #{topic}#0"
          )
          assert_equal(2, low_watermark)
        end
      end

      context "when the low watermark was already moved" do
        before do
          produce_many(topic, %w[1 2 3 4])
          Karafka::Admin.delete_records(topic => [{ partition: 0, offset: 1 }])
        end

        context "when there are messages between the low watermark and the offset" do
          before do
            Karafka.logger
              .expects(:info)
              .with("Web UI deleted offsets 1 to 2 (up to 2 messages) from #{topic}#0")
              .once

            delete "explorer/messages/#{topic}/0/3/delete"
          end

          it "deletes only the offsets above the low watermark" do
            assert_equal(302, response.status)
            assert_includes(flash[:success], "Messages in offsets 1 to 2 (up to 2 messages)")
            assert_equal(3, low_watermark)
          end
        end

        context "when the offset is below the low watermark" do
          before do
            Karafka.logger.expects(:info).with(&audit_line).never
            delete "explorer/messages/#{topic}/0/0/delete"
          end

          it "does not delete anything" do
            assert_equal(302, response.status)
            assert_includes(flash[:error], "There are no messages below offset")
            assert_equal(1, low_watermark)
          end
        end
      end

      context "when offset equals the high watermark" do
        before do
          produce_many(topic, %w[1 2 3])
          delete "explorer/messages/#{topic}/0/3/delete"
        end

        it "deletes all the messages" do
          assert_equal(302, response.status)
          assert_equal(3, low_watermark)
        end
      end

      context "when there are no messages below the offset" do
        before do
          produce_many(topic, %w[1 2 3])
          Karafka.logger.expects(:info).with(&audit_line).never
          delete "explorer/messages/#{topic}/0/0/delete"
        end

        it "does not delete anything" do
          assert_equal(302, response.status)
          assert_includes(flash[:error], "There are no messages below offset")
          assert_equal(0, low_watermark)
        end
      end

      context "when the deletion fails because of rdkafka error" do
        let(:error) do
          Rdkafka::RdkafkaError.new(
            Rdkafka::Bindings::RD_KAFKA_RESP_ERR__STATE,
            broker_message: "Not authorized"
          )
        end

        before do
          produce_many(topic, %w[1 2 3])

          Karafka::Admin.stubs(:delete_records).raises(error)

          Karafka.logger.expects(:info).with(&audit_line).never

          delete "explorer/messages/#{topic}/0/2/delete"
        end

        it "renders the confirmation with the error" do
          assert_ok
          assert_body("Please Correct the Following Errors Before Continuing")
          assert_body("Not authorized")
          assert_equal(0, low_watermark)
        end
      end
    end
  end
end
