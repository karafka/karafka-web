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
      module Ui
        module Lib
          # Reads the application routing the way the Web UI presents it. Covers consumer groups
          # only, as share groups have no Pro routing features
          class Routing
            class << self
              # @return [Array<Karafka::Routing::ConsumerGroup>] routed consumer groups
              def consumer_groups
                ::Karafka::App.routes.consumer_groups
              end

              # @param topic_id [String] route id of the topic
              # @return [Karafka::Routing::Topic, nil] consumer group topic with this route id or
              #   nil when there is none
              def find_topic(topic_id)
                consumer_groups
                  .flat_map { |consumer_group| consumer_group.topics.to_a }
                  .find { |topic| topic.id == topic_id }
              end

              # @return [Hash{String => Set<String>}] names of the topics that the active processes
              #   report as assigned, per consumer group id. It does not cover partial assignments
              #   but gives a general overview
              def assigned_topics
                assigned = Hash.new { |h, k| h[k] = Set.new }
                state = Web::Ui::Models::ConsumersState.current

                return assigned unless state

                Models::Processes.active(state).each do |process|
                  process.consumer_groups.each do |consumer_group|
                    consumer_group.subscription_groups.each do |subscription_group|
                      subscription_group.topics.each do |topic|
                        assigned[consumer_group.id.to_s] << topic.name
                      end
                    end
                  end
                end

                assigned
              end

              # @param topic [Karafka::Routing::Topic] routed topic
              # @return [Array<Hash>] `{ name:, value: }` rows for every routing setting of the
              #   topic, including its subscription group kafka and multiplexing settings
              def settings(topic)
                flattener = Web::Ui::Lib::HashFlattener
                rows = flattener.call(topic.subscription_group.kafka, "kafka")
                rows.merge!(flattener.call(topic.to_h.except(:kafka)))
                rows.merge!(flattener.call(topic.subscription_group.multiplexing.to_h, "multiplexing"))
                rows.map { |name, value| { name: name.to_s, value: value } }
              end
            end
          end
        end
      end
    end
  end
end
