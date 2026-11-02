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
          module Explorer
            module Messages
              # Deletes all the messages of a partition below a given offset by moving its low
              # watermark forward
              class DeletingController < BaseController
                # Renders the confirmation page with the number of messages that would be deleted
                #
                # @param topic_id [String]
                # @param partition_id [Integer]
                # @param offset [Integer] messages below this offset would be deleted
                def confirm(topic_id, partition_id, offset)
                  bootstrap!(topic_id, partition_id, offset)

                  render
                end

                # Deletes all the messages below the given offset
                #
                # @param topic_id [String]
                # @param partition_id [Integer]
                # @param offset [Integer] messages below this offset are deleted, the message at
                #   this offset is kept
                def delete(topic_id, partition_id, offset)
                  bootstrap!(topic_id, partition_id, offset)

                  unless @count.positive?
                    return redirect(
                      :previous,
                      error: format_flash(
                        "There are no messages below offset ? in ?#? to delete",
                        offset,
                        topic_id,
                        partition_id
                      )
                    )
                  end

                  begin
                    ::Karafka::Admin.delete_records(
                      topic_id => [{ partition: partition_id, offset: offset }]
                    )
                  rescue Rdkafka::RdkafkaError, Rdkafka::Config::ConfigError => e
                    @form_error = e
                  end

                  return confirm(topic_id, partition_id, offset) if @form_error

                  ::Karafka.logger.info(
                    "Web UI deleted offsets #{@low} to #{offset - 1} (up to #{@count} messages) " \
                    "from #{topic_id}##{partition_id}"
                  )

                  redirect(
                    "explorer/topics/#{topic_id}/#{partition_id}",
                    success: format_flash(
                      "Messages in offsets ? to ? (up to ? messages) have been deleted from ?#?",
                      @low,
                      offset - 1,
                      @count,
                      topic_id,
                      partition_id
                    )
                  )
                end

                private

                # Authorizes the deletion and computes how many offsets it would remove
                #
                # @note `@count` is the number of offsets, so an upper bound of messages: transaction
                #   control records and compacted gaps take offsets too
                #
                # @param topic_id [String]
                # @param partition_id [Integer]
                # @param offset [Integer]
                def bootstrap!(topic_id, partition_id, offset)
                  deny! unless visibility_filter.delete_records?(topic_id, partition_id)

                  @topic_id = topic_id
                  @partition_id = partition_id
                  @offset = offset

                  @low, @high = Admin.read_watermark_offsets(topic_id, partition_id)

                  # Kafka rejects deleting above the high watermark
                  not_found!(offset) if offset > @high

                  @count = [offset - @low, 0].max
                end
              end
            end
          end
        end
      end
    end
  end
end
