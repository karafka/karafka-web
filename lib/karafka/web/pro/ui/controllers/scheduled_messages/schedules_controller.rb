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
          # Namespace for all controllers related to scheduled messages
          module ScheduledMessages
            # Controller to display list of schedules (groups) and details about each
            class SchedulesController < BaseController
              # Displays list of groups
              def index
                topics = Models::Topic.all

                # Names of scheduled messages topics defined in the routing
                # They may not exist (yet) so we filter them based on the existing topics in the
                # cluster
                candidates = Karafka::App
                             .routes
                             .map { |route| route.topics.to_a }
                             .flatten
                             .select(&:scheduled_messages?)
                             .reject { |topic| topic.name.end_with?(states_postfix) }
                             .map(&:name)
                             .sort

                @topics = topics.select { |topic| candidates.include?(topic.topic_name) }

                render
              end

              # Displays all partitions statistics (if any) with number of messages to dispatch
              # @param schedule_name [String] name of the schedules messages topic
              def show(schedule_name)
                @schedule_name = schedule_name
                @stats_topic_name = "#{schedule_name}#{states_postfix}"
                @stats_info = Karafka::Admin.topic_info(@stats_topic_name)

                @states = {}
                @stats_info[:partition_count].times { |i| @states[i] = false }

                Karafka::Pro::Iterator.new({ @stats_topic_name => -1 }).each do |message|
                  @states[message.partition] = message.payload
                end

                # Sort by partition id
                @states = @states.sort_by { |key, _| key.to_s }.to_h
                # Sort daily from closest date
                @states.each_value do |details|
                  # Skip false predefined values from sorting
                  next unless details

                  details[:daily] = details[:daily].sort_by { |key, _| key.to_s }.to_h
                end

                render
              end

              private

              # @return [String] states topic postfix
              def states_postfix
                @states_postfix ||= Karafka::App.config.scheduled_messages.states_postfix
              end
            end
          end
        end
      end
    end
  end
end
