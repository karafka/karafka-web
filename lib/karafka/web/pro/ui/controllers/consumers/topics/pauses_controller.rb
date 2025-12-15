# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            # Namespace for controllers related to topic-level operations in the consumers context.
            module Topics
              # Controller for managing topic-level pauses at the consumer group level.
              #
              # Topic-level pause/resume commands are broadcast to ALL consumer processes
              # (using key='*'), and each process determines which partitions of the target
              # topic it owns and applies the command to those partitions within the specified
              # consumer group.
              class PausesController < BaseController
                self.sortable_attributes = %w[].freeze

                # Displays the pause configuration form for a topic
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                def new(consumer_group_id, topic)
                  bootstrap!(consumer_group_id, topic)

                  render
                end

                # Dispatches the topic pause command to all processes
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                def create(consumer_group_id, topic)
                  new(consumer_group_id, topic)

                  # Broadcast to all processes (key='*')
                  Commanding::Dispatcher.request(
                    Commanding::Commands::Topics::Pause.name,
                    '*',
                    {
                      consumer_group_id: consumer_group_id,
                      topic: topic,
                      # User provides this in seconds, we operate on ms in the system
                      duration: params.int(:duration) * 1_000,
                      prevent_override: params.bool(:prevent_override)
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated topic ? for ? in consumer group ?',
                      'pause',
                      topic,
                      consumer_group_id
                    )
                  )
                end

                # Displays the resume configuration form for a topic
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                def edit(consumer_group_id, topic)
                  new(consumer_group_id, topic)

                  render
                end

                # Dispatches the topic resume command to all processes
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                def delete(consumer_group_id, topic)
                  new(consumer_group_id, topic)

                  # Broadcast to all processes (key='*')
                  Commanding::Dispatcher.request(
                    Commanding::Commands::Topics::Resume.name,
                    '*',
                    {
                      consumer_group_id: consumer_group_id,
                      topic: topic,
                      reset_attempts: params.bool(:reset_attempts)
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated topic ? for ? in consumer group ?',
                      'resume',
                      topic,
                      consumer_group_id
                    )
                  )
                end

                private

                # Finds all the needed details and if not found raises a not found.
                # Uses the aggregated health stats data instead of process-specific data.
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                def bootstrap!(consumer_group_id, topic)
                  @consumer_group_id = consumer_group_id
                  @topic = topic

                  # Get aggregated stats from all processes
                  current_state = Models::ConsumersState.current!
                  @stats = Models::Health.current(current_state)

                  # Find the consumer group
                  cg_stats = @stats[@consumer_group_id]
                  cg_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)

                  # Find the topic within the consumer group
                  @topic_stats = cg_stats[:topics][@topic]
                  @topic_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)

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
