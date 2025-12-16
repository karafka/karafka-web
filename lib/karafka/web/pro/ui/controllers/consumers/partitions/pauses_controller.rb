# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            module Partitions
              # Controller for managing partition pauses at the consumer group level.
              class PausesController < BaseController
                self.sortable_attributes = %w[].freeze

                # Displays the pause configuration form for a partition
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def new(consumer_group_id, topic, partition_id)
                  bootstrap!(consumer_group_id, topic, partition_id)

                  render
                end

                # Dispatches the partition pause command to all processes
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def create(consumer_group_id, topic, partition_id)
                  new(consumer_group_id, topic, partition_id)

                  # Broadcast to all processes with matchers to filter by consumer group,
                  # topic, and partition
                  Commanding::Dispatcher.request(
                    Commanding::Commands::Partitions::Pause.name,
                    {
                      consumer_group_id: consumer_group_id,
                      topic: topic,
                      partition_id: partition_id,
                      # User provides this in seconds, we operate on ms in the system
                      duration: params.int(:duration) * 1_000,
                      prevent_override: params.bool(:prevent_override)
                    },
                    matchers: {
                      consumer_group_id: consumer_group_id,
                      topic: topic,
                      partition_id: partition_id
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated pause for partition ?#? in consumer group ?',
                      topic,
                      partition_id,
                      consumer_group_id
                    )
                  )
                end

                # Displays the resume configuration form for a partition
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def edit(consumer_group_id, topic, partition_id)
                  new(consumer_group_id, topic, partition_id)

                  render
                end

                # Dispatches the partition resume command to all processes
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def delete(consumer_group_id, topic, partition_id)
                  new(consumer_group_id, topic, partition_id)

                  # Broadcast to all processes with matchers to filter by consumer group,
                  # topic, and partition
                  Commanding::Dispatcher.request(
                    Commanding::Commands::Partitions::Resume.name,
                    {
                      consumer_group_id: consumer_group_id,
                      topic: topic,
                      partition_id: partition_id,
                      reset_attempts: params.bool(:reset_attempts)
                    },
                    matchers: {
                      consumer_group_id: consumer_group_id,
                      topic: topic,
                      partition_id: partition_id
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated resume for partition ?#? in consumer group ?',
                      topic,
                      partition_id,
                      consumer_group_id
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
