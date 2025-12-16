# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Matchers
          # Matcher that checks if the current process ID matches the specified process ID
          # in the matchers hash. This is an optional matcher that only applies when
          # process_id is specified in the matchers.
          class ProcessId < Base
            # @return [Boolean] true if process_id criterion is specified in matchers
            def apply?
              !process_id.nil?
            end

            # @return [Boolean] true if process ID matches
            def matches?
              process_id == current_process_id
            end

            private

            # @return [String, nil] process ID from matchers hash
            def process_id
              message.payload.dig(:matchers, :process_id)
            end

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
