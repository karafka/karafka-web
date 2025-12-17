# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Matchers
          # Matcher that checks if the message type header matches the expected value.
          # Used to filter command messages from result and other message types.
          # This is a required matcher that always applies.
          class MessageType < Base
            # Required matcher - check first
            self.priority = 0

            # Expected message type for commands
            COMMAND_TYPE = 'request'

            private_constant :COMMAND_TYPE

            # @return [Boolean] true if message type is a command request
            def matches?
              message.headers['type'] == COMMAND_TYPE
            end
          end
        end
      end
    end
  end
end
