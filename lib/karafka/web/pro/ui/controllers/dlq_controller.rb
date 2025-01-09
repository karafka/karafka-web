# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
