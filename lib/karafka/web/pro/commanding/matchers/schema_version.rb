# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Matchers
          # Matcher that checks if the message schema version matches the current dispatcher
          # schema version. This ensures compatibility between command producers and consumers.
          # This is a required matcher that always applies.
          class SchemaVersion < Base
            # Required matcher - check second (after message type)
            self.priority = 1

            # @return [Boolean] true if schema version matches
            def matches?
              message.payload[:schema_version] == Dispatcher::SCHEMA_VERSION
            end
          end
        end
      end
    end
  end
end
