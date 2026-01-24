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
          # Routing details - same as in OSS
          class RoutingController < BaseController
            self.sortable_attributes = %w[
              name
              active?
            ].freeze

            # Routing list
            def index
              detect_patterns_routes

              @routes = Karafka::App.routes
              @routes.each do |consumer_group|
                refine(consumer_group.topics)
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

              render
            end

            # Given route details
            #
            # @param topic_id [String] topic id
            def show(topic_id)
              detect_patterns_routes

              @topic = Karafka::Routing::Router.find_by(id: topic_id)

              @topic || not_found!(topic_id)

              render
            end

            private

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
