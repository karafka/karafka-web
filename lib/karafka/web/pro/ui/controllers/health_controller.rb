# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
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

            # We filter on the consumer group and topic names (the structural keys of the stats
            # tree) plus the process/partition id exposed by the leaf records. Match-propagation
            # keeps a consumer group or topic when any of its descendants matches.
            self.filterable_attributes = %w[
              id
            ].freeze

            # Displays the current system state
            def overview
              current_state = Models::ConsumersState.current!
              @stats = Models::Health.current(current_state)

              # Sort only on a per topic basis not to resort higher levels
              @stats.each_value do |cg_details|
                cg_details.each_value { |topic_details| sort(topic_details) }
              end

              # Narrow down the whole tree to the consumer groups/topics/partitions matching the
              # current filter (if any). It is safe to prune in place here as the stats are built
              # fresh per request.
              filter_health(@stats)

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
                cg_details.each_value { |topic_details| sort(topic_details) }
              end

              filter_health(@stats)

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

            private

            # Fields exposed by the health filtering selector. They map to the two structural levels
            # of the stats tree (topic and consumer group names) rather than record attributes.
            HEALTH_FILTERABLE_FIELDS = %i[
              topic
              consumer_group
            ].freeze

            # Narrows the health stats tree by the current filter.
            #
            # `topic` and `consumer_group` are structural keys of the tree (not record attributes),
            # so we scope them here by matching the relevant key. The plain keyword form (no field)
            # falls back to the generic match-propagation engine, which matches across every level.
            #
            # @param stats [Hash] the health stats tree (mutated in place)
            # @return [Hash] the filtered stats
            def filter_health(stats)
              unless @params.current_filter.empty?
                value = @params.current_filter.downcase

                case @params.current_filter_field
                when "consumer_group"
                  stats.select! { |cg_id, _| cg_id.to_s.downcase.include?(value) }
                when "topic"
                  stats.each_value do |cg|
                    health_topics(cg).select! { |name, _| name.to_s.downcase.include?(value) }
                  end
                  stats.reject! { |_cg_id, cg| health_topics(cg).empty? }
                else
                  filter(stats)
                end
              end

              # Expose the selector fields last, so the `filter` call above (which resets
              # @filterable_fields to the engine's allow-list) does not clobber them
              @filterable_fields = HEALTH_FILTERABLE_FIELDS

              stats
            end

            # @param consumer_group_details [Hash] a single consumer group's stats
            # @return [Hash] its topics hash, regardless of the stats shape (the overview nests them
            #   under `:topics`, cluster lags keys them directly)
            def health_topics(consumer_group_details)
              if consumer_group_details.key?(:topics)
                consumer_group_details[:topics]
              else
                consumer_group_details
              end
            end
          end
        end
      end
    end
  end
end
