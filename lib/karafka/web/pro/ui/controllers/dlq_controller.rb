# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # DLQ topics overview
          class DlqController < BaseController
            # Lists DLQ topics
            def index
              topics = Karafka::App.consumer_groups.flat_map(&:topics).flat_map(&:to_a)

              dlq_topic_patterns = topics
                .map { |source_topic| source_topic.dead_letter_queue.topic }
                .uniq
                .compact
                .select(&:itself)

              dlq_topic_patterns += Web.config.ui.dlq_patterns

              @dlq_topics = Models::ClusterInfo
                .topics
                .select { |topic| dlq?(dlq_topic_patterns, topic[:topic_name]) }
                .sort_by { |topic| topic[:topic_name] }

              render
            end

            private

            # Checks if topic is in topics we consider DLQ or if it matches any predefined regular
            # expressions used for auto-DLQ discovery
            #
            # @param topics_matches [Array<String, Regexp>] array with list of DLQ topics matches
            #   from the routing and regular expressions for auto-discovery
            # @param name [String] topic name for which we want to know if it is used in DLQ
            # @return [Boolean] is the given topic a DLQ topic
            def dlq?(topics_matches, name)
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
