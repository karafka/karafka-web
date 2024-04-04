# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # Health state controller
          class HealthController < BaseController
            self.sortable_attributes = %w[
              id
              lag
              lag_d
              lag_stored
              lag_stored_d
              lag_hybrid
              lag_hybrid_d
              committed_offset
              committed_offset_fd
              stored_offset
              stored_offset_fd
              hi_offset
              hi_offset_fd
              ls_offset
              ls_offset_fd
              fetch_state
              poll_state
              lso_risk_state
              name
              poll_state_ch
            ].freeze

            # Displays the current system state
            def overview
              current_state = Models::ConsumersState.current!
              @stats = Models::Health.current(current_state)

              # Refine only on a per topic basis not to resort higher levels
              @stats.each_value do |cg_details|
                cg_details.each_value { |topic_details| refine(topic_details) }
              end

              render
            end

            # Displays details about lags and their progression/statuses
            def lags
              # Same data as overview but presented differently
              overview

              render
            end

            # Displays lags for routing defined consumer groups taken from the cluster and not
            # the metrics reported. This is useful when we don't have any consumers running but
            # still want to check lags because it shows what Kafka sees
            def cluster_lags
              @stats = Models::Health.cluster_lags_with_offsets

              @stats.each_value do |cg_details|
                cg_details.each_value { |topic_details| refine(topic_details) }
              end

              render
            end

            # Displays details about offsets and their progression/statuses
            def offsets
              # Same data as overview but presented differently
              overview

              render
            end

            # Displays information related to time of changes of particular attributes
            def changes
              # Same data as overview but presented differently
              overview

              render
            end
          end
        end
      end
    end
  end
end
