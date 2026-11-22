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
          # Sends a copy of a message to a topic, as the Web UI Explorer republish action
          class RepublishMessage < Base
            tool(
              "karafka_republish_message",
              <<~TEXT.tr("\n", " ").strip,
                Sends a copy of a message to a target topic, as the Web UI Explorer republish
                action does (for example from a DLQ back to its source topic), and returns the
                partition and offset the copy got.
              TEXT
              contract: Contracts::Republishing.new,
              operation: :produce,
              properties: {
                topic: { type: "string", description: "Topic of the source message" },
                partition: { type: "integer", minimum: 0, description: "Source message partition" },
                offset: { type: "integer", minimum: 0, description: "Source message offset" },
                target_topic: { type: "string", description: "Topic to send the copy to" },
                target_partition: {
                  type: "integer",
                  minimum: 0,
                  description: "Target partition. Without it, the key or the partitioner picks one"
                },
                include_source_headers: {
                  type: "boolean",
                  description: "Copy the source message headers. Defaults to true"
                },
                skip_validation: {
                  type: "boolean",
                  description: "Skip the payload consistency check of the Web UI"
                }
              },
              required: %w[topic partition offset target_topic]
            )

            # The messages policy must allow it, as for the Web UI action
            #
            # @raise [Errors::Mcp::InvalidArgumentsError] when the source message does not exist
            def authorize!
              return if ::Karafka::Web.config.ui.policies.messages.republish?(message)

              deny!("The messages policy denies republishing this message")
            end

            # @return [Array<String>] the target topic
            def topics
              [@arguments.fetch(:target_topic)]
            end

            # @return [Array(String, String)] Web UI request of the matching action
            def ui_request
              source = @arguments.values_at(:topic, :partition, :offset).join("/")

              ["POST", "/explorer/messages/#{source}/republish"]
            end

            private

            # @return [Hash] delivery details
            def fetch
              target_topic = @arguments.fetch(:target_topic)

              form = Ui::Lib::Explorer::Republishing::Normalizer.call(
                target_topic: target_topic,
                target_partition: @arguments.fetch(:target_partition, "").to_s,
                include_source_headers: @arguments.fetch(:include_source_headers, true).to_s,
                skip_validation: @arguments[:skip_validation].to_s
              )

              errors = Ui::Lib::Explorer::Republishing::Contracts::Form.new.call(
                form.merge(
                  target_partitions_count: target_partitions_count(target_topic),
                  source_message: message
                )
              ).errors

              unless errors.empty?
                raise(
                  Errors::Mcp::NoDataError,
                  errors.map { |key, error| "#{key} #{error}" }.join(", ")
                )
              end

              delivery = Ui::Lib::Explorer::Publishing::Dispatcher.new(
                Ui::Lib::Explorer::Republishing::Transform.call(message, form)
              ).call

              { topic: delivery.topic, partition: delivery.partition, offset: delivery.offset }
            end

            # @param target_topic [String]
            # @return [Integer, nil] partitions count of the target topic or nil when it does not
            #   exist, as in the Web UI, so the form contract reports it
            def target_partitions_count(target_topic)
              Web::Ui::Models::ClusterInfo.partitions_count(target_topic)
            rescue Errors::Ui::NotFoundError
              nil
            end

            # @return [Karafka::Messages::Message] source message
            def message
              @message ||= Web::Ui::Models::Message.find(
                @arguments.fetch(:topic),
                @arguments.fetch(:partition),
                @arguments.fetch(:offset)
              )
            rescue Errors::Ui::NotFoundError
              raise Errors::Mcp::InvalidArgumentsError, "No source message under these coordinates"
            end
          end
        end
      end
    end
  end
end
