# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Adds the paused_partitions_lag cache used to compensate for stale self-reported
          # lag on partitions that have been paused long enough for their librdkafka high
          # watermark cache to go stale.
          class AddPausedPartitionsLag < Base
            self.versions_until = "1.5.0"
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              state[:paused_partitions_lag] = {}
            end
          end
        end
      end
    end
  end
end
