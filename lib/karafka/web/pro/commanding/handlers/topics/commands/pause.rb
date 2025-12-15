# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Topics
            module Commands
              # Executes the topic-level pause request to pause all partitions of a topic
              # that are assigned to this consumer process within the target consumer group.
              class Pause < Base
                # 10 years in ms - effectively forever
                FOREVER_MS = 10 * 365 * 24 * 60 * 60 * 1000

                private_constant :FOREVER_MS

                # Triggers pausing of all partitions for the target topic that are owned by
                # this process. Supports prevent_override to skip already paused partitions.
                # Only applies to partitions belonging to the target consumer group.
                def call
                  # Skip if this listener's subscription group doesn't belong to the target
                  # consumer group. This is important when multiple consumer groups consume
                  # the same topic - we only want to pause partitions for the specific group.
                  unless matches_consumer_group?
                    result('skipped', partitions_affected: [], partitions_prevented: [])
                    return
                  end

                  partitions_affected = []
                  partitions_prevented = []

                  duration = request[:duration]
                  duration = FOREVER_MS if duration.zero?
                  prevent_override = request[:prevent_override]

                  owned_partition_ids.each do |partition_id|
                    coordinator = coordinator_for(partition_id)

                    # If prevent_override is set and partition is already paused, skip it
                    if coordinator.pause_tracker.paused? && prevent_override
                      partitions_prevented << partition_id
                      next
                    end

                    coordinator.pause_tracker.pause(duration)
                    client.pause(topic, partition_id, nil, duration)

                    partitions_affected << partition_id
                  end

                  result(
                    'applied',
                    partitions_affected: partitions_affected,
                    partitions_prevented: partitions_prevented
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
