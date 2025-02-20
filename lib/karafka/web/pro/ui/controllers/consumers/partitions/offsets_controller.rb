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
              # Partition offset management controller in the context of current consumer process
              # assignments
              class OffsetsController < BaseController
                self.sortable_attributes = [].freeze

                # Displays the offset edit page with the edit form or a warning when not applicable
                #
                # @param process_id [String] id of the process we're interested in
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def edit(process_id, subscription_group_id, topic, partition_id)
                  bootstrap!(process_id, subscription_group_id, topic, partition_id)

                  render
                end

                # Triggers the offset change in the running process via the commanding API
                #
                # @param process_id [String] id of the process we're interested in
                # @param subscription_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def update(process_id, subscription_group_id, topic, partition_id)
                  edit(process_id, subscription_group_id, topic, partition_id)

                  offset = params.int(:offset)
                  prevent_overtaking = params.bool(:prevent_overtaking)
                  force_resume = params.bool(:force_resume)

                  Commanding::Dispatcher.request(
                    Commanding::Commands::Partitions::Seek.name,
                    process_id,
                    {
                      consumer_group_id: @consumer_group.id,
                      subscription_group_id: @subscription_group.id,
                      topic: topic,
                      partition_id: partition_id,
                      offset: offset,
                      prevent_overtaking: prevent_overtaking,
                      force_resume: force_resume
                    }
                  )

                  redirect(
                    :previous,
                    success: format_flash(
                      'Initiated offset adjustment to ? for ?#? (subscription group: ?)',
                      offset,
                      topic,
                      partition_id,
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
