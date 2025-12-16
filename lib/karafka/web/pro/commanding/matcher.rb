# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Matcher that makes a decision whether a given command message should be applied/executed
        # within the context of the current consumer process.
        #
        # Since we use the `assign`, each process listens to this topic and receives messages
        # with commands targeting all the processes, this is why it needs to be filtered.
        #
        # The matcher supports a `matchers` field in the payload that allows for granular filtering
        # based on various criteria like consumer_group_id, topic, etc. Each criterion is checked
        # by a dedicated sub-matcher class.
        class Matcher
          # Maps matcher type symbols to their corresponding sub-matcher classes
          MATCHER_CLASSES = {
            consumer_group_id: Matchers::ConsumerGroupId,
            topic: Matchers::Topic
          }.freeze

          private_constant :MATCHER_CLASSES

          # @param message [Karafka::Messages::Message] message with command
          # @return [Boolean] is this message dedicated to current process and is actionable
          def matches?(message)
            # We operate only on commands. Result and other messages should be ignored
            return false unless message.headers['type'] == 'request'
            # We want to work only with commands that target all processes or our current
            return false unless message.key == '*' || message.key == process_id
            # Ignore messages that have different schema. This can happen in the middle of
            # upgrades of the framework. We ignore this not to risk compatibility issues
            return false unless message.payload[:schema_version] == Dispatcher::SCHEMA_VERSION
            # Check if all matchers (if any) are satisfied by this process
            return false unless matchers_match?(message)

            true
          end

          private

          # @return [String] current process id
          def process_id
            @process_id ||= ::Karafka::Web.config.tracking.consumers.sampler.process_id
          end

          # Checks if all matchers specified in the message payload are satisfied by this process.
          # If no matchers are specified, returns true (matches all).
          #
          # @param message [Karafka::Messages::Message] message with command
          # @return [Boolean] true if all matchers match or no matchers specified
          def matchers_match?(message)
            matchers = message.payload[:matchers]

            # No matchers means match all processes
            return true unless matchers
            return true if matchers.empty?

            # All matchers must match (AND logic)
            matchers.all? do |matcher_type, matcher_value|
              match_criterion?(matcher_type, matcher_value)
            end
          end

          # Checks if a single matcher criterion is satisfied using the appropriate sub-matcher
          #
          # @param matcher_type [Symbol] type of matcher (:consumer_group_id, :topic, etc.)
          # @param matcher_value [String] value to match against
          # @return [Boolean] true if the criterion matches
          def match_criterion?(matcher_type, matcher_value)
            matcher_class = MATCHER_CLASSES[matcher_type]

            # Unknown matcher types are ignored (treated as matching)
            # This allows forward compatibility - older consumers ignore new matcher types
            return true unless matcher_class

            matcher_class.new(matcher_value).matches?
          end
        end
      end
    end
  end
end
