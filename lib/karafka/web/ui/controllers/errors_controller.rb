# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Errors displaying controller
        # It supports only scenarios with a single partition for errors
        # If you have high load of errors, consider going Pro
        class ErrorsController < BaseController
          # Lists first page of the errors
          def index
            @watermark_offsets = Models::WatermarkOffsets.find(errors_topic, 0)
            previous_offset, @error_messages, next_offset, = current_page_data

            paginate(
              previous_offset,
              @params.current_offset,
              next_offset,
              # If message is an array, it means it's a compacted dummy offset representation
              @error_messages.map { |message| message.is_a?(Array) ? message.last : message.offset }
            )

            render
          end

          # @param offset [Integer] given error message offset
          def show(offset)
            @partition_id = 0
            @offset = offset

            watermark_offsets = Models::WatermarkOffsets.find(errors_topic, @partition_id)

            @error_message = Models::Message.find(
              errors_topic,
              @partition_id,
              offset,
              watermark_offsets: watermark_offsets
            )

            paginate(offset, watermark_offsets.low, watermark_offsets.high)

            render
          end

          private

          # @return [Array] Array with requested messages as well as pagination details and other
          #   obtained metadata
          def current_page_data
            Models::Message.offset_page(
              errors_topic,
              0,
              @params.current_offset,
              @watermark_offsets
            )
          end

          # @return [String] errors topic
          def errors_topic
            ::Karafka::Web.config.topics.errors.name
          end
        end
      end
    end
  end
end
