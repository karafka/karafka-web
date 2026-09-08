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
            module Partitions
              # Partition offset management controller at the consumer group level.
              class OffsetsController < BaseController
                self.sortable_attributes = [].freeze

                # Displays the offset edit page with the edit form or a warning when not applicable
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def edit(consumer_group_id, topic, partition_id)
                  bootstrap!(consumer_group_id, topic, partition_id)

                  render
                end

                # Triggers the offset change in the running process via the commanding API
                #
                # @param consumer_group_id [String]
                # @param topic [String]
                # @param partition_id [Integer]
                def update(consumer_group_id, topic, partition_id)
                  bootstrap!(consumer_group_id, topic, partition_id)

                  command_form = Lib::Commands::Normalizer.seek(params)
                  errors = Lib::Commands::Contracts::Seek.new.call(command_form).errors

                  unless errors.empty?
                    return redirect(
                      :previous,
                      error: format_flash(
                        "Could not adjust the offset for ?#? in consumer group ?: ?",
                        topic,
                        partition_id,
                        consumer_group_id,
                        errors.values.join(", ")
                      )
                    )
                  end

                  Lib::Commands::Dispatcher.new(
                    Lib::Commands::Transform.partition_seek(
                      command_form.merge(
                        consumer_group_id: consumer_group_id,
                        topic: topic,
                        partition_id: partition_id
                      )
                    )
                  ).call

                  redirect(
                    :previous,
                    success: format_flash(
                      "Initiated offset adjustment to ? for ?#? in consumer group ?",
                      command_form.fetch(:offset),
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
