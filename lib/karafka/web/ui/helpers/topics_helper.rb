# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helper module for formatting Kafka topic and partition information
        # in various contexts within the Karafka Web UI.
        #
        # This module provides consistent formatting for topic-partition assignments
        # across different display contexts like inline text, labels, and identifiers.
        #
        # @see https://karafka.io/docs/Development-Naming-Conventions
        module TopicsHelper
          # Default limit for displaying partitions before truncation
          DEFAULT_LIMIT = 5

          # Formats topic and partitions for inline text display in views.
          #
          # This method is optimized for compact display in assignments, logs, and
          # other inline contexts where space is limited.
          #
          # @param topic [String] the Kafka topic name
          # @param partitions [Array<Integer>, Integer] partition number(s) to format
          # @param limit [Integer] maximum number of partitions to display before truncation
          # @return [String] formatted topic-partition string
          #
          # @example Single partition
          #   topics_assignment_text("user-events", 0)
          #   # => "user-events-[0]"
          #
          # @example Multiple consecutive partitions
          #   topics_assignment_text("user-events", [0, 1, 2, 3])
          #   # => "user-events-[0-3]"
          #
          # @example Multiple non-consecutive partitions
          #   topics_assignment_text("user-events", [0, 2, 4])
          #   # => "user-events-[0,2,4]"
          #
          # @example Truncated partitions list
          #   topics_assignment_text("user-events", [0, 1, 2, 3, 4, 5, 6], limit: 3)
          #   # => "user-events-[0,1,2...]"
          #
          # @example Empty partitions
          #   topics_assignment_text("user-events", [])
          #   # => "user-events"
          def topics_assignment_text(topic, partitions, limit: DEFAULT_LIMIT)
            partitions = Array(partitions)

            if partitions.empty?
              topic
            elsif partitions.size == 1
              "#{topic}-[#{partitions.first}]"
            else
              sorted_partitions = partitions.map(&:to_i).sort
              # Check for consecutive first (best representation)
              if topics_consecutive?(sorted_partitions) && sorted_partitions.size > 2
                "#{topic}-[#{sorted_partitions.first}-#{sorted_partitions.last}]"
              # Apply limit if specified and partitions exceed it
              elsif limit && sorted_partitions.size > limit
                displayed_partitions = sorted_partitions.first(limit)
                "#{topic}-[#{displayed_partitions.join(',')}...]"
              else
                "#{topic}-[#{sorted_partitions.join(',')}]"
              end
            end
          end

          # Formats topic and partitions for human-readable labels and headers.
          #
          # This method provides more descriptive formatting suitable for page titles,
          # section headers, and other contexts where additional context is helpful.
          #
          # @param topic [String] the Kafka topic name
          # @param partitions [Array<Integer>, Integer] partition number(s) to format
          # @param limit [Integer] maximum number of partitions to display before truncation
          # @return [String] formatted topic-partition label with additional context
          #
          # @example Consecutive partitions with count
          #   topics_assignment_label("user-events", [0, 1, 2, 3])
          #   # => "user-events-[0-3] (4 partitions total)"
          #
          # @example Truncated with remaining count
          #   topics_assignment_label("user-events", [0, 1, 2, 3, 4, 5], limit: 3)
          #   # => "user-events-[0,1,2] (+3 more)"
          #
          # @example Non-consecutive partitions
          #   topics_assignment_label("user-events", [0, 2, 4])
          #   # => "user-events-[0,2,4]"
          def topics_assignment_label(topic, partitions, limit: DEFAULT_LIMIT)
            partitions = Array(partitions)

            sorted_partitions = partitions.map(&:to_i).sort
            if topics_consecutive?(sorted_partitions)
              "#{topic}-[#{sorted_partitions.first}-#{sorted_partitions.last}] " \
                "(#{partitions.size} partitions total)"
            elsif sorted_partitions.size > limit
              displayed = sorted_partitions.first(limit)
              remaining = sorted_partitions.size - limit
              "#{topic}-[#{displayed.join(',')}] (+#{remaining} more)"
            else
              "#{topic}-[#{sorted_partitions.join(',')}]"
            end
          end

          # Creates a specific identifier for topic-partition combinations.
          #
          # This method generates consistent identifiers used in metrics collection,
          # cache keys, and other contexts requiring unique topic-partition identification.
          #
          # @param topic [String] the Kafka topic name
          # @param partition [Integer] the partition number
          # @return [String] formatted topic-partition identifier
          #
          # @example Basic identifier
          #   topics_partition_identifier("user-events", 0)
          #   # => "user-events-0"
          #
          # @example Used for cache keys
          #   cache_key = topics_partition_identifier("orders", 3)
          #   Rails.cache.fetch(cache_key) { expensive_operation }
          def topics_partition_identifier(topic, partition)
            "#{topic}-#{partition}"
          end

          private

          # Checks if an array of sorted integers contains consecutive numbers.
          #
          # This helper method determines whether partition numbers form a continuous
          # sequence, which allows for more compact display formatting.
          #
          # @param sorted_array [Array<Integer>] array of sorted integers to check
          # @return [Boolean] true if all numbers are consecutive, false otherwise
          #
          # @example Consecutive numbers
          #   topics_consecutive?([1, 2, 3, 4])  # => true
          #
          # @example Non-consecutive numbers
          #   topics_consecutive?([1, 3, 5, 7])  # => false
          #
          # @example Single element (not consecutive)
          #   topics_consecutive?([1])  # => false
          #
          # @example Empty array (not consecutive)
          #   topics_consecutive?([])  # => false
          def topics_consecutive?(sorted_array)
            return false if sorted_array.size < 2

            sorted_array.each_cons(2).all? { |a, b| b == a + 1 }
          end
        end
      end
    end
  end
end
