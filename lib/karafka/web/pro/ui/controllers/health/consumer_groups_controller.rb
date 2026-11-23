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
          module Health
            # Consumer groups of the whole cluster, including the ones the Web UI does not manage
            # or receive reports from. The list shows states only; details, members and committed
            # offsets with lags are loaded per group, each on its own page.
            class ConsumerGroupsController < BaseController
              self.sortable_attributes = {
                index: %w[id state].freeze,
                offsets: %w[id lag stored_offset].freeze
              }.freeze

              self.filterable_attributes = {
                index: %i[id state]
              }.freeze

              # Cluster state should always be fresh and not from cache
              before { cache.clear }

              # Lists all the consumer groups in the cluster with their states
              def index
                @consumer_groups = filter(sort(Models::Cluster::ConsumerGroup.all))

                render
              end

              # Displays the state, protocol, assignor and coordinator of a consumer group
              #
              # @param group_id [String] consumer group id
              def overview(group_id)
                @consumer_group = Models::Cluster::ConsumerGroup.find(group_id)

                render
              end

              # Displays the members of a consumer group with their assignments
              #
              # @param group_id [String] consumer group id
              def members(group_id)
                @consumer_group = Models::Cluster::ConsumerGroup.find(group_id)

                render
              end

              # Displays the committed offsets of a consumer group with their lags
              #
              # @param group_id [String] consumer group id
              def offsets(group_id)
                @consumer_group = Models::Cluster::ConsumerGroup.find(group_id)
                @topics = @consumer_group.topics
                @topics.each_value { |partitions| sort(partitions) }

                render
              end
            end
          end
        end
      end
    end
  end
end
