# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        class Matcher
          module Matchers
            # Matcher that checks if the current process ID matches the specified value.
            # Supports '*' as a wildcard to match all processes.
            class ProcessId < Base
              # @return [Boolean] true if process ID matches or value is '*'
              def matches?
                return true if value == '*'

                value == current_process_id
              end

              private

              # @return [String] current process ID from sampler
              def current_process_id
                ::Karafka::Web.config.tracking.consumers.sampler.process_id
              end
            end
          end
        end
      end
    end
  end
end
