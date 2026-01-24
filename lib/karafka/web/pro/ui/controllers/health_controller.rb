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
