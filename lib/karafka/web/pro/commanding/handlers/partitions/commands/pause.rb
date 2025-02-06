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
              # Executes the pause request to pause (or prolong) partition
              class Pause < Base
                # 10 years in ms
                FOREVER_MS = 10 * 365 * 24 * 60 * 60 * 1000

                private_constant :FOREVER_MS

                # Triggers pausing of a given topic partition or updates the pause
                def call
                  # If pause is already there and we don't want to change the way it is, we skip
                  if coordinator.pause_tracker.paused? && request[:prevent_override]
                    result('prevented')

                    return
                  end

                  duration = request[:duration]
                  duration = FOREVER_MS if duration.zero?

                  coordinator.pause_tracker.pause(duration)
                  client.pause(topic, partition_id, nil, duration)

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
