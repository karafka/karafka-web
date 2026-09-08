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
          module Consumers
            # Namespace for controllers related to topic-level operations in the consumers context.
            module Topics
              # Controller for managing topic-level pauses at the consumer group level.
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
                  bootstrap!(consumer_group_id, topic)

                  command_form = Lib::Consumers::Commands::Normalizer.pause(params)
                  errors = Lib::Consumers::Commands::Contracts::Pause.new.call(command_form).errors

                  unless errors.empty?
                    return redirect(
                      :previous,
                      error: format_flash(
                        "Could not pause the ? topic in consumer group ?: ?",
                        topic,
                        consumer_group_id,
                        errors.values.join(", ")
                      )
                    )
                  end

                  Lib::Consumers::Commands::Dispatcher.new(
                    Lib::Consumers::Commands::Transform.topic_pause(
                      command_form.merge(
                        consumer_group_id: consumer_group_id,
                        topic: topic
                      )
                    )
                  ).call

                  redirect(
                    :previous,
                    success: format_flash(
                      "Initiated pause for all partitions of the ? topic in consumer group ?",
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
                  bootstrap!(consumer_group_id, topic)

                  Lib::Consumers::Commands::Dispatcher.new(
                    Lib::Consumers::Commands::Transform.topic_resume(
                      Lib::Consumers::Commands::Normalizer.resume(params).merge(
                        consumer_group_id: consumer_group_id,
                        topic: topic
                      )
                    )
                  ).call

                  redirect(
                    :previous,
                    success: format_flash(
                      "Initiated resume for all partitions of the ? topic in consumer group ?",
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
                  @routing_topic = find_routing_topic(@consumer_group_id, @topic)

                  # May not be found when not all routing is available. In such cases we assume
                  # that topic is not LRJ and it's up to the end user to handle this correctly.
                  @topic_lrj = @routing_topic&.long_running_job?

                  # Check if any active process is running (needed to issue commands)
                  @any_process_running = Models::Processes.active(current_state).any? do |process|
                    process.status == "running"
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
