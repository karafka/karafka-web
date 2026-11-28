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
          # Settings of one routed topic, as on the Web UI Routing topic details page
          class RoutingTopic < Base
            include Web::Ui::Helpers::FormattingHelper

            # Settings with these in their names hold credentials and are never shown
            SECRET_SCOPES = %w[
              sasl
              ssl
            ].freeze

            private_constant :SECRET_SCOPES

            tool(
              "karafka_routing_topic",
              <<~TEXT.tr("\n", " ").strip,
                Settings of one routed topic, as on the Web UI Routing topic details page: its
                consumer group, subscription group and every routing setting as a flat name and
                value list, with values as the Web UI renders them. It includes the kafka settings
                of its subscription group and the multiplexing settings. Values of sasl and ssl
                settings are masked. Use karafka_routing to find the route id.
              TEXT
              contract: Contracts::Routing::Topic.new,
              required: %w[topic_id],
              properties: {
                topic_id: {
                  type: "string",
                  description: "Route id of the topic from karafka_routing"
                }
              }
            )

            private

            # @return [Hash] routed topic settings
            def fetch
              topic_id = @arguments.fetch(:topic_id)

              Ui::Lib::PatternsDetector.new.call

              topic = ::Karafka::Routing::Router.find_by(id: topic_id)

              unless topic
                raise Errors::Mcp::NoDataError, "No routed topic with id #{topic_id}. " \
                  "Call karafka_routing to list the routed topics"
              end

              {
                id: topic.id,
                name: topic.name,
                consumer_group: topic.consumer_group.id,
                subscription_group: topic.subscription_group.name,
                settings: settings(topic)
              }
            end

            # @param topic [Karafka::Routing::Topic]
            # @return [Array<Hash>] name and value of every routing setting, sorted by name. Values
            #   are strings, as the Web UI renders them
            def settings(topic)
              flattener = Web::Ui::Lib::HashFlattener
              rows = flattener.call(topic.subscription_group.kafka, "kafka")
              rows.merge!(flattener.call(topic.to_h.except(:kafka)))
              rows.merge!(flattener.call(topic.subscription_group.multiplexing.to_h, "multiplexing"))

              rows.sort_by { |name, _| name.to_s }.map do |name, value|
                secret = SECRET_SCOPES.any? { |scope| name.to_s.include?(scope) }

                { name: name.to_s, value: secret ? "***" : object_value_to_s(value) }
              end
            end
          end
        end
      end
    end
  end
end
