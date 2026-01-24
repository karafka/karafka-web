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
          # Matcher that checks if the current process has any assignments for the consumer
          # group ID specified in the message matchers. Uses the Karafka assignments tracker
          # to check actual current assignments rather than just routing configuration.
          # This is an optional matcher that only applies when consumer_group_id is specified.
          class ConsumerGroupId < Base
            # @return [Boolean] true if consumer_group_id criterion is specified in matchers
            def apply?
              !consumer_group_id.nil?
            end

            # Checks if this process has any assignments for the specified consumer group
            #
            # @return [Boolean] true if this process has partitions assigned for the consumer group
            def matches?
              ::Karafka::App.assignments.any? do |topic, _partitions|
                topic.consumer_group.id == consumer_group_id
              end
            end

            private

            # @return [String, nil] consumer group ID from matchers hash
            def consumer_group_id
              message.payload.dig(:matchers, :consumer_group_id)
            end
          end
        end
      end
    end
  end
end
