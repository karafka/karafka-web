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
            include Ui::Lib::Paginations

            # Lists all the topics we can explore
            def index
              @topics = Models::ClusterInfo
                        .topics
                        .reject { |topic| topic[:topic_name] == '__consumer_offsets' }
                        .sort_by { |topic| topic[:topic_name] }

              respond
            end

            # Displays aggregated messages from (potentially) all partitions of a topic
            #
            # @param topic_id [String]
            #
            # @note This view may not be 100% accurate because we merge multiple partitions data
            #   into a single view and this is never accurate. It can be used however to quickly
            #   look at most recent data flowing, etc, hence it is still useful for aggregated
            #   metrics information
            #
            # @note We cannot use offset references here because each of the partitions may have
            #   completely different values
            def topic(topic_id)
              @topic_id = topic_id
              @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

              @active_partitions, materialized_page, @limited = Paginators::Partitions.call(
                @partitions_count, @params.current_page
              )

              @messages, next_page = Models::Message.topic_page(
                topic_id, @active_partitions, materialized_page
              )

              paginate(@params.current_page, next_page)

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
              @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

              previous_offset, @messages, next_offset = current_partition_data

              paginate(
                previous_offset,
                @params.current_offset,
                next_offset,
                @messages.map(&:offset)
              )

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
            # @return [Array] fetched data with pagination information for the requested partition
            def current_partition_data
              Ui::Models::Message.offset_page(
                @topic_id,
                @partition_id,
                @params.current_offset,
                @watermark_offsets
              )
            end
          end
        end
      end
    end
  end
end
