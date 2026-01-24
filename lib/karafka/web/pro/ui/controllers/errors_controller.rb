# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # Errors details controller
          class ErrorsController < BaseController
            # Lists all the errors from all the partitions
            def index
              @topic_id = errors_topic
              @partitions_count = Models::ClusterInfo.partitions_count(errors_topic)

              @active_partitions, materialized_page, @limited = Paginators::Partitions.call(
                @partitions_count, @params.current_page
              )

              @error_messages, next_page = Models::Message.topic_page(
                errors_topic, @active_partitions, materialized_page
              )

              paginate(@params.current_page, next_page)

              render
            end

            # @param partition_id [Integer] id of the partition of errors we are interested in
            def partition(partition_id)
              @topic_id = errors_topic
              @partition_id = partition_id
              @watermark_offsets = Models::WatermarkOffsets.find(errors_topic, @partition_id)
              @partitions_count = Models::ClusterInfo.partitions_count(errors_topic)

              previous_offset, @error_messages, next_offset = Models::Message.offset_page(
                errors_topic,
                @partition_id,
                @params.current_offset,
                @watermark_offsets
              )

              # If message is an array, it means it's a compacted dummy offset representation
              mapped = @error_messages.map do |message|
                message.is_a?(Array) ? message.last : message.offset
              end

              paginate(previous_offset, @params.current_offset, next_offset, mapped)

              render
            end

            # Shows given error details
            #
            # @param partition_id [Integer]
            # @param offset [Integer]
            def show(partition_id, offset)
              @partition_id = partition_id
              @offset = offset

              watermark_offsets = Models::WatermarkOffsets.find(errors_topic, partition_id)

              @error_message = Models::Message.find(
                errors_topic,
                partition_id,
                offset,
                watermark_offsets: watermark_offsets
              )

              paginate(offset, watermark_offsets.low, watermark_offsets.high)

              render
            end

            private

            # @return [String] errors topic
            def errors_topic
              ::Karafka::Web.config.topics.errors.name
            end
          end
        end
      end
    end
  end
end
