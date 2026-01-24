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
