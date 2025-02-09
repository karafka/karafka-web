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
              # Controller for managing partitions pauses in the context of the given consumer
              # process
              class PausesController < BaseController
                self.sortable_attributes = %w[].freeze

                # Displays the toggle (pause / resume)
                #
                # @param process_id [String] id of the process we're interested in
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def new(process_id, subscription_group_id, topic, partition_id)
                  bootstrap!(process_id, subscription_group_id, topic, partition_id)

                  render
                end

                # @param process_id [String]
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def create(process_id, subscription_group_id, topic, partition_id)
                  new(process_id, subscription_group_id, topic, partition_id)

                  Commanding::Dispatcher.request(
                    Commanding::Commands::Partitions::Pause.name,
                    process_id,
                    {
                      consumer_group_id: @consumer_group.id,
                      subscription_group_id: @subscription_group.id,
                      topic: topic,
                      partition_id: partition_id,
                      # User provides this in seconds, we operate on ms in the system
                      duration: params.int(:duration) * 1_000,
                      prevent_override: params.bool(:prevent_override)
                    }
                  )

                  redirect(
                    "consumers/#{process_id}/subscriptions",
                    success: <<~MESSAGE
                      Initiated partition pause for #{topic}##{partition_id}
                      (subscription group: #{subscription_group_id})
                    MESSAGE
                  )
                end

                # @param process_id [String]
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def edit(process_id, subscription_group_id, topic, partition_id)
                  new(process_id, subscription_group_id, topic, partition_id)

                  render
                end

                # @param process_id [String]
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def delete(process_id, subscription_group_id, topic, partition_id)
                  new(process_id, subscription_group_id, topic, partition_id)

                  Commanding::Dispatcher.request(
                    Commanding::Commands::Partitions::Resume.name,
                    process_id,
                    {
                      consumer_group_id: @consumer_group.id,
                      subscription_group_id: @subscription_group.id,
                      topic: topic,
                      partition_id: partition_id,
                      reset_attempts: params.bool(:reset_attempts)
                    }
                  )

                  redirect(
                    "consumers/#{process_id}/subscriptions",
                    success: <<~MESSAGE
                      Initiated partition resume for #{topic}##{partition_id}
                      (subscription group: #{subscription_group_id})
                    MESSAGE
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
