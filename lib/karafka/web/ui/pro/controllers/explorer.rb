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
          # Data explorer controller
          class Explorer < Ui::Controllers::Base
            # Lists all the topics we can explore
            def index
              @topics = Karafka::Admin
                        .cluster_info
                        .topics
                        .reject { |topic| topic[:topic_name] == '__consumer_offsets' }
                        .sort_by { |topic| topic[:topic_name] }

              respond
            end

            # Shows messages available in a given partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            def partition(topic_id, partition_id)
              @topic_id = topic_id
              @partition_id = partition_id
              @watermark_offsets = Ui::Models::WatermarkOffsets.find(topic_id, partition_id)

              previous_offset, @messages, next_offset, @partitions_count = current_page_data

              paginate(previous_offset, @params.current_offset, next_offset)

              respond
            end

            # Displays given message
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer] offset of the message we want to display
            def show(topic_id, partition_id, offset)
              @topic_id = topic_id
              @partition_id = partition_id
              @offset = offset
              @message = Ui::Models::Message.find(@topic_id, @partition_id, @offset)
              @payload_error = false

              @decrypt = if ::Karafka::App.config.encryption.active
                           ::Karafka::Web.config.ui.decrypt
                         else
                           true
                         end

              begin
                @pretty_payload = JSON.pretty_generate(@message.payload)
              rescue StandardError => e
                @payload_error = e
              end

              respond
            end

            private

            # Fetches current page data
            # @param [Array] fetched data with pagination information
            def current_page_data
              Ui::Models::Message.offset_page(
                @topic_id,
                @partition_id,
                @params.current_offset,
                @watermark_offsets[:low],
                @watermark_offsets[:high]
              )
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
