# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            module Topics
              # Controller for managing topic-level pauses in the context of consumer processes.
              #
              # Topic-level pause/resume commands are broadcast to ALL consumer processes
              # (using key='*'), and each process determines which partitions of the target
              # topic it owns and applies the command to those partitions.
              class PausesController < BaseController
                self.sortable_attributes = %w[].freeze

                # Displays the pause configuration form for a topic
                #
                # @param process_id [String] id of the process we're viewing from (for context)
                # @param subscription_group_id [String]
                # @param topic [String]
                def new(process_id, subscription_group_id, topic)
                  bootstrap!(process_id, subscription_group_id, topic)

                  render
                end

                # Dispatches the topic pause command to all processes
                #
                # @param process_id [String] id of the process we're viewing from (for context)
                # @param subscription_group_id [String]
                # @param topic [String]
                def create(process_id, subscription_group_id, topic)
                  new(process_id, subscription_group_id, topic)

                  # Broadcast to all processes (key='*')
                  Commanding::Dispatcher.request(
                    Commanding::Commands::Topics::Pause.name,
                    '*',
                    {
                      consumer_group_id: @consumer_group.id,
                      subscription_group_id: @subscription_group.id,
                      topic: topic,
                      # User provides this in seconds, we operate on ms in the system
                      duration: params.int(:duration) * 1_000,
                      prevent_override: params.bool(:prevent_override)
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated topic ? for ? (subscription group: ?)',
                      'pause',
                      topic,
                      subscription_group_id
                    )
                  )
                end

                # Displays the resume configuration form for a topic
                #
                # @param process_id [String] id of the process we're viewing from (for context)
                # @param subscription_group_id [String]
                # @param topic [String]
                def edit(process_id, subscription_group_id, topic)
                  new(process_id, subscription_group_id, topic)

                  render
                end

                # Dispatches the topic resume command to all processes
                #
                # @param process_id [String] id of the process we're viewing from (for context)
                # @param subscription_group_id [String]
                # @param topic [String]
                def delete(process_id, subscription_group_id, topic)
                  new(process_id, subscription_group_id, topic)

                  # Broadcast to all processes (key='*')
                  Commanding::Dispatcher.request(
                    Commanding::Commands::Topics::Resume.name,
                    '*',
                    {
                      consumer_group_id: @consumer_group.id,
                      subscription_group_id: @subscription_group.id,
                      topic: topic,
                      reset_attempts: params.bool(:reset_attempts)
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated topic ? for ? (subscription group: ?)',
                      'resume',
                      topic,
                      subscription_group_id
                    )
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
