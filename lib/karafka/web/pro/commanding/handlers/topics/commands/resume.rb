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
