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
        # Namespace for individual matcher implementations used by the Matcher class.
        # Each sub-matcher is responsible for checking a single criterion
        # (e.g., consumer_group_id, topic).
        module Matchers
          # Base class for all sub-matchers.
          #
          # Sub-matchers receive the full message and extract the relevant data they need.
          # This provides a consistent API across all matchers.
          #
          # Matchers have two methods:
          # - `apply?` - returns true if this matcher's criterion is present and should be checked
          # - `matches?` - returns true if the criterion matches (only called if apply? is true)
          #
          # Required matchers (MessageType, SchemaVersion) always apply.
          # Optional matchers (ProcessId, ConsumerGroupId, Topic) decide if they should be applied
          #   based on the message details
          class Base
            class << self
              # Sets the priority for this matcher class
              # @param value [Integer] priority value
              attr_writer :priority

              # Priority determines the order in which matchers are checked.
              # Lower values are checked first. Required matchers should have lower priority.
              #
              # @return [Integer] matcher priority (default: 100)
              def priority
                @priority || 100
              end
            end

            # @param message [Karafka::Messages::Message] the command message to match against
            def initialize(message)
              @message = message
            end

            # Checks if this matcher should be applied to the message.
            # Override in subclasses for optional matchers.
            #
            # @return [Boolean] true if this matcher should check the message
            def apply?
              true
            end

            # Checks if the criterion is satisfied.
            # Only called when apply? returns true.
            #
            # @return [Boolean] true if matches
            def matches?
              raise NotImplementedError, "Implement in a subclass"
            end

            private

            attr_reader :message
          end
        end
      end
    end
  end
end
