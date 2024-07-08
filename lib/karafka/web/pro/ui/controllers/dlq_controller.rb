# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
