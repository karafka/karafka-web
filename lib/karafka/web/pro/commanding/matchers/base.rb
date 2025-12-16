# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
              raise NotImplementedError, 'Implement in a subclass'
            end

            private

            attr_reader :message
          end
        end
      end
    end
  end
end
