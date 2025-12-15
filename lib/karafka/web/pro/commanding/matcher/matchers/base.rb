# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        class Matcher
          # Namespace for individual matcher implementations
          module Matchers
            # Base class for all sub-matchers. Each sub-matcher is responsible for checking
            # a single criterion (e.g., consumer_group_id, topic).
            #
            # Sub-matchers must implement the #matches? method which returns true if the
            # criterion is satisfied by the current process.
            class Base
              # @param value [String] the value to match against
              def initialize(value)
                @value = value
              end

              # Checks if the criterion is satisfied
              #
              # @return [Boolean] true if matches
              def matches?
                raise NotImplementedError, 'Implement in a subclass'
              end

              private

              attr_reader :value
            end
          end
        end
      end
    end
  end
end
