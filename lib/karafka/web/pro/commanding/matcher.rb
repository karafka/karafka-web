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
        class Matcher
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
            # For commands that target a specific consumer group (like topics.pause/resume),
            # we can skip processing if this process doesn't have that consumer group in its routing.
            # This prevents unnecessary processing when broadcasting to all processes.
            return false unless consumer_group_matches?(message)

            true
          end

          private

          # @return [String] current process id
          def process_id
            @process_id ||= ::Karafka::Web.config.tracking.consumers.sampler.process_id
          end

          # Checks if the command's consumer_group_id (if present) matches any consumer group
          # in this process's routing. This optimization prevents processing commands intended
          # for consumer groups that this process doesn't manage.
          #
          # @param message [Karafka::Messages::Message] message with command
          # @return [Boolean] true if no consumer_group_id specified or if it matches routing
          def consumer_group_matches?(message)
            consumer_group_id = message.payload.dig(:command, :consumer_group_id)

            # If no consumer_group_id in the command, allow it (backwards compatibility)
            return true unless consumer_group_id

            # Check if any of our consumer groups match the requested one
            consumer_group_ids.include?(consumer_group_id)
          end

          # @return [Set<String>] set of consumer group IDs in this process's routing
          def consumer_group_ids
            @consumer_group_ids ||= ::Karafka::App.routes.map(&:id).to_set
          end
        end
      end
    end
  end
end
