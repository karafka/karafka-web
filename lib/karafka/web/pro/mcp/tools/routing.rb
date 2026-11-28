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
          # Routing of the application, as on the Web UI Routing page
          class Routing < Base
            tool(
              "karafka_routing",
              <<~TEXT.tr("\n", " ").strip,
                Routing of the application, as on the Web UI Routing page: consumer groups with
                their routed topics, each with its route id, subscription group id, pattern type,
                multiplexing, whether it is active and whether any running consumer process
                reports it as assigned. Use karafka_routing_topic with the route id to read the
                settings of one routed topic.
              TEXT
              contract: Contracts::NoArguments.new
            )

            private

            # @return [Hash] routing data
            def fetch
              Ui::Lib::PatternsDetector.new.call

              assigned = Ui::Lib::Routing.assigned_topics

              consumer_groups = Ui::Lib::Routing.consumer_groups.map do |consumer_group|
                {
                  id: consumer_group.id,
                  topics: consumer_group.topics.map do |topic|
                    serialize(topic, assigned[consumer_group.id.to_s].include?(topic.name))
                  end
                }
              end

              { consumer_groups: consumer_groups }
            end

            # @param topic [Karafka::Routing::Topic]
            # @param assigned [Boolean] is the topic assigned to any active process
            # @return [Hash] routed topic details
            def serialize(topic, assigned)
              subscription_group = topic.subscription_group
              multiplexing = subscription_group.multiplexing
              multiplexed = subscription_group.multiplexing?

              {
                id: topic.id,
                name: topic.name,
                subscription_group: subscription_group.id,
                type: topic.patterns.type,
                multiplexing: multiplexed ? { min: multiplexing.min, max: multiplexing.max } : nil,
                assigned: assigned,
                active: topic.active?
              }
            end
          end
        end
      end
    end
  end
end
