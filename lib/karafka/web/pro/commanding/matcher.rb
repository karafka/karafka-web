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
            matches = true

            # We want to work only with commands that target all processes or our current
            matches = false unless message.key == '*' || message.key == process_id
            # We operate only on commands. Result messages should be ignored
            matches = false unless message.payload[:type] == 'command'
            # Ignore messages that have different schema. This can happen in the middle of
            # upgrades of the framework. We ignore this not to risk compatibility issues
            matches = false unless message.payload[:schema_version] == Dispatcher::SCHEMA_VERSION

            matches
          end

          private

          # @return [String] current process id
          def process_id
            @process_id ||= ::Karafka::Web.config.tracking.consumers.sampler.process_id
          end
        end
      end
    end
  end
end
