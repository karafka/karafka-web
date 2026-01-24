# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
                def call
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
