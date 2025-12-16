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
              # Resumes all paused partitions for a topic that are assigned to this consumer process
              # within the target consumer group.
              class Resume < Base
                # Expires the pause on all partitions for the target topic so Karafka resumes
                # processing of those partitions.
                def call
                  partitions_affected = []

                  owned_partition_ids.each do |partition_id|
                    coordinator = coordinator_for(partition_id)

                    coordinator.pause_tracker.expire
                    coordinator.pause_tracker.reset if request[:reset_attempts]

                    partitions_affected << partition_id
                  end

                  result('applied', partitions_affected: partitions_affected)
                end
              end
            end
          end
        end
      end
    end
  end
end
