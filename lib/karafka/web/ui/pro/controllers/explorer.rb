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
              @topics = topics
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
            #
            # @note This view is also limited to `max_aggregable_partitions` because librdkafka
            #   at the moment does not support querying for watermark offsets in batches
            def topic(topic_id)
              topic = topics.find { |topic_data| topic_data[:topic_name] == topic_id }
              topic || raise(Web::Errors::Ui::NotFoundError, topic_id)

              @topic_id = topic_id
              @partitions_count = topic[:partition_count]
              @max_aggregable_partitions = Web.config.ui.explorer.max_aggregable_partitions

              @messages, next_page, @limited = Models::Message.topic_page(
                topic_id, @params.current_page, @partitions_count
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

              previous_offset, @messages, next_offset, @partitions_count = current_partition_data

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
                           ::Karafka::Web.config.ui.explorer.decrypt
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

            # @return [Array<?>]
            def topics
                Karafka::Admin
                  .cluster_info
                  .topics
            end

            # Fetches current page data
            # @return [Array] fetched data with pagination information for the requested partition
            def current_partition_data
              Ui::Models::Message.offset_page(
                @topic_id,
                @partition_id,
                @params.current_offset,
                @watermark_offsets[:low],
                @watermark_offsets[:high]
              )
            end
          end
        end
      end
    end
  end
end
