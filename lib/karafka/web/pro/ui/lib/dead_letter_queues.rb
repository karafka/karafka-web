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
          # Finds the dead letter queue topics the way the Web UI DLQ page lists them
          class DeadLetterQueues
            class << self
              # @return [Array<Ui::Models::Cluster::Topic>] cluster topics that the routing uses as
              #   dead letter queues or that match `ui.dlq_patterns`, sorted by name
              def topics
                patterns = Routing
                  .consumer_groups
                  .flat_map { |consumer_group| consumer_group.topics.to_a }
                  .map { |source_topic| source_topic.dead_letter_queue.topic }
                  .uniq
                  .compact
                  .select(&:itself)

                patterns += ::Karafka::Web.config.ui.dlq_patterns

                Models::Cluster::Topic
                  .all
                  .select { |topic| dead_letter_queue?(patterns, topic[:topic_name]) }
                  .sort_by { |topic| topic[:topic_name] }
              end

              private

              # Checks if topic is in topics we consider DLQ or if it matches any predefined
              # regular expressions used for auto-DLQ discovery
              #
              # @param topics_matches [Array<String, Regexp>] array with list of DLQ topics matches
              #   from the routing and regular expressions for auto-discovery
              # @param name [String] topic name for which we want to know if it is used in DLQ
              # @return [Boolean] is the given topic a DLQ topic
              def dead_letter_queue?(topics_matches, name)
                topics_matches.any? do |candidate|
                  candidate.is_a?(Regexp) ? candidate.match?(name) : candidate == name
                end
              end
            end
          end
        end
      end
    end
  end
end
