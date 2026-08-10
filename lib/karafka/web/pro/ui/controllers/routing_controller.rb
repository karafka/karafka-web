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
          # Routing details - same as in OSS
          class RoutingController < BaseController
            self.sortable_attributes = %w[
              name
              active?
              value
            ].freeze

            # Routing list
            def index
              detect_patterns_routes

              @routes = Karafka::App.routes
              @routes.each do |consumer_group|
                sort(consumer_group.topics)
              end

              current_state = Models::ConsumersState.current
              @assigned = Hash.new { |h, k| h[k] = Set.new }

              # If there are active processes, we can use their data to mark certain topics as
              # assigned. This does not cover the full scope as some partitions may be assigned
              # and some not, but provides general overview
              if current_state
                Models::Processes.active(current_state).each do |process|
                  process.consumer_groups.each do |consumer_group|
                    consumer_group.subscription_groups.each do |subscription_group|
                      subscription_group.topics.each do |topic|
                        @assigned[consumer_group.id.to_s] << topic.name
                      end
                    end
                  end
                end
              end

              # Routing is filtered at the view level (via `visible_topics`), so we expose the
              # filterable fields here for the filtering box to render its selector
              @filterable_fields = %i[topic consumer_group]

              render
            end

            # Given route details
            #
            # @param topic_id [String] topic id
            def show(topic_id)
              detect_patterns_routes

              @topic = Karafka::Routing::Router.find_by(id: topic_id)

              @topic || not_found!(topic_id)

              # Present the routing settings as a flat, sortable + filterable list of name/value rows
              @details = sort(filter(topic_detail_rows(@topic), fields: %i[name value]))

              render
            end

            private

            # @param topic [Karafka::Routing::Topic] topic we present the routing details for
            # @return [Array<Hash>] `{ name:, value: }` rows for every routing setting (including
            #   the Pro multiplexing settings)
            def topic_detail_rows(topic)
              rows = flatten_hash(topic.subscription_group.kafka, "kafka")
              rows.merge!(flatten_hash(topic.to_h.except(:kafka)))
              rows.merge!(flatten_hash(topic.subscription_group.multiplexing.to_h, "multiplexing"))
              rows.map { |name, value| { name: name.to_s, value: value } }
            end

            # Detect routes defined as patterns
            def detect_patterns_routes
              Lib::PatternsDetector.new.call
            end
          end
        end
      end
    end
  end
end
