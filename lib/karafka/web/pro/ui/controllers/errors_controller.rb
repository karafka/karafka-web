# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
