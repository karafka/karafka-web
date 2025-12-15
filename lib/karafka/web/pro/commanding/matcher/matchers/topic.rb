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
            # topic name. Uses the Karafka assignments tracker to check actual current
            # assignments rather than just routing configuration.
            class Topic < Base
              # Checks if this process has any partitions assigned for the specified topic
              #
              # @return [Boolean] true if this process has partitions assigned for the topic
              def matches?
                ::Karafka::App.assignments.any? do |topic, _partitions|
                  topic.name == value
                end
              end
            end
          end
        end
      end
    end
  end
end
