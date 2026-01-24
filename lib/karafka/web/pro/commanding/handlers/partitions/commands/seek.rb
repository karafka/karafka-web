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
              # Moves the offset and optionally also resumes processing (if applicable) to where
              # user wanted
              class Seek < Base
                # Runs seeking with some extra options if applicable
                def call
                  # If user enabled overtaking prevention and we're already ahead of the requested
                  # offset, we should ditch such a request
                  if prevent_overtaking? &&
                     coordinator.seek_offset &&
                     coordinator.seek_offset >= desired_offset
                    result('prevented')

                    return
                  end

                  # Mark previous offset as consumed. We move the offset in case the first message
                  # after seeking would be a poison pill. That way the offset position is
                  # moved even if we get a rebalance later.
                  assigned = client.mark_as_consumed!(
                    seek_message(desired_offset - 1)
                  )

                  # If we were not able to mark as consumed it means that the assignment was lost
                  # We should signal this and stop
                  unless assigned
                    result('lost_partition')

                    return
                  end

                  client.seek(seek_message(desired_offset))

                  coordinator.seek_offset = desired_offset
                  # Clear the attempts. Previous attempts should not count to a changed offset and
                  # we should start with a clean slate. That's why we reset the tracker
                  coordinator.pause_tracker.reset
                  # If there was a pause and if user no longer wants to wait until it expires, we
                  # can reset it so the work starts immediately.
                  coordinator.pause_tracker.expire if force_resume?

                  result('applied')
                end

                private

                # @param offset [Integer] desired seek offset
                # @return [::Karafka::Messages::Seek] builds a seek message for offset change
                def seek_message(offset)
                  ::Karafka::Messages::Seek.new(topic, partition_id, offset)
                end

                # @return [Integer] desired offset to move to
                def desired_offset
                  @desired_offset ||= request[:offset]
                end

                # @return [Boolean] does user want to use the overtaking prevention
                def prevent_overtaking?
                  request[:prevent_overtaking]
                end

                # @return [Boolean] should we resume immediately instead of waiting until the pause
                #   timeout expires
                def force_resume?
                  request[:force_resume]
                end
              end
            end
          end
        end
      end
    end
  end
end
