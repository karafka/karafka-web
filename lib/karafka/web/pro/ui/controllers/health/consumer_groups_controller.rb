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
                members: %w[member_id client_id host group_instance_id].freeze,
                topics: %w[name partitions_count lag max_lag avg_lag].freeze,
                offsets: %w[topic_name id lag stored_offset].freeze
              }.freeze

              self.filterable_attributes = {
                index: %i[id state],
                members: %i[member_id client_id host group_instance_id],
                topics: %i[name],
                offsets: %i[topic_name]
              }.freeze

              # Consumer groups are never cached, but the topics and offsets pages query all the
              # topics from the cached cluster metadata, which would miss recently created topics
              before(:topics, :offsets) { cache.clear }

              # Lists all the consumer groups in the cluster with their states
              def index
                @consumer_groups, last_page = Paginators::Arrays.call(
                  filter(sort(Models::Cluster::ConsumerGroup.all)),
                  @params.current_page
                )

                paginate(@params.current_page, !last_page)

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

                # Filtering and sorting work in place, so we use a copy to keep the members count
                @members, last_page = Paginators::Arrays.call(
                  filter(sort(@consumer_group.members.dup)),
                  @params.current_page
                )

                paginate(@params.current_page, !last_page)

                @processes_by_member_id = processes_by_member_id

                render
              end

              # Displays the topics a consumer group committed offsets for, with their lags
              # aggregated per topic and the offsets deletion action, which works per topic
              #
              # @param group_id [String] consumer group id
              def topics(group_id)
                @consumer_group = Models::Cluster::ConsumerGroup.find(group_id)

                topics = @consumer_group
                  .offsets
                  .group_by { |partition| partition[:topic_name] }
                  .map do |topic_name, partitions|
                    Models::Health::AggregatedClusterTopic.new(topic_name, partitions)
                  end

                @topics, last_page = Paginators::Arrays.call(
                  filter(sort(topics)),
                  @params.current_page
                )

                paginate(@params.current_page, !last_page)

                render
              end

              # Displays the committed offsets of a consumer group with their lags
              #
              # @param group_id [String] consumer group id
              def offsets(group_id)
                @consumer_group = Models::Cluster::ConsumerGroup.find(group_id)

                @offsets, last_page = Paginators::Arrays.call(
                  filter(sort(@consumer_group.offsets)),
                  @params.current_page
                )

                paginate(@params.current_page, !last_page)

                render
              end

              private

              # @return [Hash{String => Hash}] Karafka processes subscription groups by the member
              #   id they report (`:process_id`, `:subscription_group_id`). Members of applications
              #   that do not report to the Web UI (e.g. non-Ruby ones) have no entry.
              def processes_by_member_id
                state = Models::ConsumersState.current

                return {} unless state

                Models::Processes.active(state).each_with_object({}) do |process, mapping|
                  process.consumer_groups.each do |consumer_group|
                    consumer_group.subscription_groups.each do |subscription_group|
                      # Reports of processes running versions that do not track it have no member id
                      member_id = subscription_group[:member_id].to_s

                      next if member_id.empty?

                      mapping[member_id] = {
                        process_id: process.id,
                        subscription_group_id: subscription_group.id
                      }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
