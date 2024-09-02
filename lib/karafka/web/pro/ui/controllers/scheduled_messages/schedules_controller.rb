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
                             .map(&:topics)
                             .map(&:to_a)
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
