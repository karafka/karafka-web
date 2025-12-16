# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Matchers
          # Matcher that checks if the current process has any assignments for the topic
          # specified in the message matchers. Uses the Karafka assignments tracker to check
          # actual current assignments rather than just routing configuration.
          # This is an optional matcher that only applies when topic is specified.
          class Topic < Base
            # @return [Boolean] true if topic criterion is specified in matchers
            def apply?
              !topic_name.nil?
            end

            # Checks if this process has any partitions assigned for the specified topic
            #
            # @return [Boolean] true if this process has partitions assigned for the topic
            def matches?
              ::Karafka::App.assignments.any? do |topic, _partitions|
                topic.name == topic_name
              end
            end

            private

            # @return [String, nil] topic name from matchers hash
            def topic_name
              message.payload.dig(:matchers, :topic)
            end
          end
        end
      end
    end
  end
end
