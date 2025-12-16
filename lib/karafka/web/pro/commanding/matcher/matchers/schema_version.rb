# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        class Matcher
          module Matchers
            # Matcher that checks if the message schema version matches the current dispatcher
            # schema version. This ensures compatibility between command producers and consumers.
            class SchemaVersion < Base
              # @return [Boolean] true if schema version matches
              def matches?
                value == Dispatcher::SCHEMA_VERSION
              end
            end
          end
        end
      end
    end
  end
end
