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

module Karafka
  module Web
    module Pro
      module Mcp
        module Tools
          # Publishes a message, as the Web UI Explorer publish action
          class PublishMessage < Base
            tool(
              "karafka_publish_message",
              <<~TEXT.tr("\n", " ").strip,
                Publishes a message to a topic, as the Web UI Explorer publish action does, and
                returns the partition and offset it got. Payload and key are strings. Headers
                are "name: value" lines.
              TEXT
              contract: Contracts::Publishing.new,
              operation: :produce,
              properties: {
                topic: { type: "string", description: "Topic to publish to" },
                payload: { type: "string", description: "Message payload" },
                key: { type: "string", description: "Message key" },
                partition: {
                  type: "integer",
                  minimum: 0,
                  description: "Target partition. Without it, the key or the partitioner picks one"
                },
                headers: { type: "string", description: "Headers, one \"name: value\" per line" },
                tombstone: { type: "boolean", description: "Publish a null payload" },
                skip_validation: {
                  type: "boolean",
                  description: "Skip the payload consistency check of the Web UI"
                }
              },
              required: %w[topic]
            )

            # The messages policy must allow it, as for the Web UI action
            def authorize!
              return if ::Karafka::Web.config.ui.policies.messages.publish?(topic)

              deny!("The messages policy denies publishing to this topic")
            end

            # @return [Array<String>] the target topic
            def topics
              [topic]
            end

            private

            # @return [Hash] delivery details
            def fetch
              form = Ui::Lib::Explorer::Publishing::Normalizer.call(
                payload: @arguments.fetch(:payload, ""),
                key: @arguments.fetch(:key, ""),
                partition: @arguments.fetch(:partition, "").to_s,
                headers: @arguments.fetch(:headers, ""),
                tombstone: @arguments[:tombstone].to_s,
                skip_validation: @arguments[:skip_validation].to_s
              )

              errors = Ui::Lib::Explorer::Publishing::Contracts::Form.new.call(
                form.merge(partitions_count: Web::Ui::Models::ClusterInfo.partitions_count(topic), topic: topic)
              ).errors

              unless errors.empty?
                raise(
                  Errors::Mcp::NoDataError,
                  errors.map { |key, message| "#{key} #{message}" }.join(", ")
                )
              end

              delivery = Ui::Lib::Explorer::Publishing::Dispatcher.new(
                Ui::Lib::Explorer::Publishing::Transform.call(topic, form)
              ).call

              { topic: delivery.topic, partition: delivery.partition, offset: delivery.offset }
            end

            # @return [String]
            def topic
              @arguments.fetch(:topic)
            end
          end
        end
      end
    end
  end
end
