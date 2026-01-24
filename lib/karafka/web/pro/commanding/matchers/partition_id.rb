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
