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
        # The matcher uses a set of sub-matchers, each responsible for checking a specific
        # criterion. Matchers have two methods:
        # - `apply?` - returns true if the matcher's criterion is present in the message
        # - `matches?` - returns true if the criterion matches (only checked if apply? is true)
        #
        # Matcher classes are auto-loaded from the Matchers namespace and sorted by priority.
        # Required matchers (MessageType, SchemaVersion) have lower priority and are checked first.
        class Matcher
          class << self
            # @return [Array<Class>] all matcher classes sorted by priority
            def matcher_classes
              @matcher_classes ||= Matchers
                                   .constants
                                   .map { |name| Matchers.const_get(name) }
                                   .select { |klass| klass.is_a?(Class) && klass < Matchers::Base }
                                   .sort_by(&:priority)
                                   .freeze
            end
          end

          # @param message [Karafka::Messages::Message] message with command
          # @return [Boolean] is this message dedicated to current process and is actionable
          def matches?(message)
            self
              .class
              .matcher_classes
              .lazy
              .map { |klass| klass.new(message) }
              .select(&:apply?)
              .all?(&:matches?)
          end
        end
      end
    end
  end
end
