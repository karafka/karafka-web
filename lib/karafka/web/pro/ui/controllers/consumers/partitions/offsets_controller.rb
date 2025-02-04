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
              class OffsetsController < BaseController
                self.sortable_attributes = %w[
                  id
                  lag_hybrid
                  committed_offset
                  stored_offset
                  poll_state
                ].freeze

                # @param process_id [String] id of the process we're interested in
                def index(process_id)
                  subscriptions(process_id)

                  render
                end

                # Displays the edit page
                #
                # @param process_id [String] id of the process we're interested in
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def edit(process_id, subscription_group_id, topic, partition_id)
                  subscriptions(process_id)
                  bootstrap!(@process.consumer_groups, process_id, subscription_group_id, topic, partition_id)

                  render
                end

                # Triggers the offset change in the running process via the commanding
                #
                # @param process_id [String] id of the process we're interested in
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def update(process_id, subscription_group_id, topic, partition_id)
                  edit(process_id, subscription_group_id, topic, partition_id)

                  offset = @params[:offset].to_i
                  prevent_overtaking = @params[:prevent_overtaking] == 'on'
                  force_unpause = @params[:force_unpause] == 'on'

                  Commanding::Dispatcher.command(
                    Commanding::Commands::Partitions::Seek.id,
                    process_id,
                    {
                      consumer_group_id: @consumer_group.id,
                      subscription_group_id: @subscription_group.id,
                      topic: topic,
                      partition_id: partition_id,
                      offset: offset,
                      prevent_overtaking: prevent_overtaking,
                      force_unpause: force_unpause
                    }
                  )

                  redirect(
                    "consumers/#{process_id}/partitions",
                    success: <<~MESSAGE
                      Initiated offset adjustment to #{offset}
                      for #{topic}##{partition_id}
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
