# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Ui
      module Pro
        module Controllers
          # Errors details controller
          class Errors < Ui::Controllers::Base
            # @param partition_id [Integer] id of the partition of errors we are interested in
            def index(partition_id)
              @partition_id = partition_id
              @watermark_offsets = Ui::Models::WatermarkOffsets.find(errors_topic, @partition_id)

              previous_page, @error_messages, next_page, @partitions_count = current_page_data

              paginate(previous_page, @params.current_offset, next_page)

              respond
            end

            # Shows given error details
            #
            # @param partition_id [Integer]
            # @param offset [Integer]
            def show(partition_id, offset)
              @partition_id = partition_id
              @offset = offset
              @error_message = Models::Message.find(
                errors_topic,
                @partition_id,
                @offset
              )

              respond
            end

            private

            # @return [Array] Array with requested messages as well as pagination details and other
            #   obtained metadata
            def current_page_data
              Models::Message.offset_page(
                errors_topic,
                @partition_id,
                @params.current_offset,
                @watermark_offsets[:low],
                @watermark_offsets[:high]
              )
            end

            # @return [String] errors topic
            def errors_topic
              ::Karafka::Web.config.topics.errors
            end

            # @return [Class] offset based pagination
            def pagination_engine
              Ui::Lib::Paginations::OffsetBased
            end
          end
        end
      end
    end
  end
end
