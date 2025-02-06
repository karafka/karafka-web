# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for request.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Partitions
            module Commands
              # Resumes paused partition
              class Resume < Base
                # Expires the pause so Karafka resumes processing of the given topic partition
                def call
                  coordinator.pause_tracker.expire
                  coordinator.pause_tracker.reset if request[:reset_attempts]

                  result('applied')
                end
              end
            end
          end
        end
      end
    end
  end
end
