# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            # Namespace for controllers related to working with particular partitions in the
            # context of consumers processes
            module Partitions
              # Base controller for all the partition related management stuff
              class BaseController < ConsumersController
                private

                # Finds all the needed details and if not found raises a not found.
                # Uses the aggregated health stats data instead of process-specific data.
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def bootstrap!(consumer_group_id, topic, partition_id)
                  @consumer_group_id = consumer_group_id
                  @topic = topic
                  @partition_id = partition_id.to_i

                  # Get aggregated stats from all processes
                  current_state = Models::ConsumersState.current!
                  @stats = Models::Health.current(current_state)

                  # Find the consumer group
                  cg_stats = @stats[@consumer_group_id]
                  cg_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)

                  # Find the topic within the consumer group
                  @topic_stats = cg_stats[:topics][@topic]
                  @topic_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)

                  # Find the partition within the topic
                  @partition_stats = @topic_stats[:partitions][@partition_id]
                  @partition_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)

                  # Check if topic is LRJ from routing
                  routing_topics = Karafka::App.routes.flat_map(&:topics).flat_map(&:to_a)

                  @routing_topic = routing_topics.find do |r_topic|
                    r_topic.consumer_group.id == @consumer_group_id &&
                      r_topic.name == @topic
                  end

                  # May not be found when not all routing is available. In such cases we assume
                  # that topic is not LRJ and it's up to the end user to handle this correctly.
                  @topic_lrj = @routing_topic&.long_running_job?

                  # Check if any active process is running (needed to issue commands)
                  @any_process_running = Models::Processes.active(current_state).any? do |process|
                    process.status == 'running'
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
