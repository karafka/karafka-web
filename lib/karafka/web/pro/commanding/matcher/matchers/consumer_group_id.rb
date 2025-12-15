# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        class Matcher
          module Matchers
            # Matcher that checks if the current process has any assignments for a given
            # consumer group ID. Uses the Karafka assignments tracker to check actual
            # current assignments rather than just routing configuration.
            class ConsumerGroupId < Base
              # Checks if this process has any assignments for the specified consumer group
              #
              # @return [Boolean] true if this process has partitions assigned for the consumer group
              def matches?
                ::Karafka::App.assignments.any? do |topic, _partitions|
                  topic.consumer_group.id == value
                end
              end
            end
          end
        end
      end
    end
  end
end
