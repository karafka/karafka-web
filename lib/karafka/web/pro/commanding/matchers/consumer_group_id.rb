# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
