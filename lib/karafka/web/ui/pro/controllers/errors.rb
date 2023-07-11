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
            include Ui::Lib::Paginations

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

              respond
            end

            # @param partition_id [Integer] id of the partition of errors we are interested in
            def partition(partition_id)
              @partition_id = partition_id
              @watermark_offsets = Ui::Models::WatermarkOffsets.find(errors_topic, @partition_id)
              @partitions_count = Models::ClusterInfo.partitions_count(errors_topic)

              previous_offset, @error_messages, next_offset = Models::Message.offset_page(
                errors_topic,
                @partition_id,
                @params.current_offset,
                @watermark_offsets
              )

              paginate(
                previous_offset,
                @params.current_offset,
                next_offset,
                @error_messages.map(&:offset)
              )

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

            # @return [String] errors topic
            def errors_topic
              ::Karafka::Web.config.topics.errors
            end
          end
        end
      end
    end
  end
end
