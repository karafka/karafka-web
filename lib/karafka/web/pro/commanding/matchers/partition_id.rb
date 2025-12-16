# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Matchers
          # Matcher that checks if the current process has a specific partition assigned.
          # Uses the Karafka assignments tracker to check actual current assignments.
          # This is an optional matcher that only applies when partition_id is specified.
          #
          # @note This matcher only checks for partition_id presence across all topics.
          #   For topic-specific partition matching, use this in combination with the
          #   Topic matcher.
          class PartitionId < Base
            # @return [Boolean] true if partition_id criterion is specified in matchers
            def apply?
              !partition_id.nil?
            end

            # Checks if this process has the specified partition assigned (any topic)
            #
            # @return [Boolean] true if this process has the partition assigned
            def matches?
              ::Karafka::App.assignments.any? do |_topic, partitions|
                partitions.include?(partition_id)
              end
            end

            private

            # @return [Integer, nil] partition ID from matchers hash
            def partition_id
              message.payload.dig(:matchers, :partition_id)
            end
          end
        end
      end
    end
  end
end
