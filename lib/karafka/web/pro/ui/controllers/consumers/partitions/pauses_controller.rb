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
                  bootstrap!(consumer_group_id, topic, partition_id)

                  command_form = Lib::Consumers::Commands::Normalizer.pause(params)
                  errors = Lib::Consumers::Commands::Contracts::Pause.new.call(command_form).errors

                  unless errors.empty?
                    return redirect(
                      :previous,
                      error: format_flash(
                        "Could not pause partition ?#? in consumer group ?: ?",
                        topic,
                        partition_id,
                        consumer_group_id,
                        errors.values.join(", ")
                      )
                    )
                  end

                  Lib::Consumers::Commands::Dispatcher.new(
                    Lib::Consumers::Commands::Transform.partition_pause(
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
                      "Initiated pause for partition ?#? in consumer group ?",
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
                  bootstrap!(consumer_group_id, topic, partition_id)

                  Lib::Consumers::Commands::Dispatcher.new(
                    Lib::Consumers::Commands::Transform.partition_resume(
                      Lib::Consumers::Commands::Normalizer.resume(params).merge(
                        consumer_group_id: consumer_group_id,
                        topic: topic,
                        partition_id: partition_id
                      )
                    )
                  ).call

                  redirect(
                    :previous,
                    success: format_flash(
                      "Initiated resume for partition ?#? in consumer group ?",
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
