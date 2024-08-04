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
    module Pro
      module Ui
        module Controllers
          # Data explorer controller
          class ExplorerController < BaseController
            # Lists all the topics we can explore
            def index
              @topics = Models::ClusterInfo
                        .topics
                        .sort_by { |topic| topic[:topic_name] }

              unless ::Karafka::Web.config.ui.visibility.internal_topics
                @topics.reject! { |topic| topic[:topic_name].start_with?('__') }
              end

              render
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
              @visibility_filter = ::Karafka::Web.config.ui.policies.messages

              @topic_id = topic_id
              @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

              @active_partitions, materialized_page, @limited = Paginators::Partitions.call(
                @partitions_count, @params.current_page
              )

              @messages, next_page = Models::Message.topic_page(
                topic_id, @active_partitions, materialized_page
              )

              paginate(@params.current_page, next_page)

              render
            end

            # Shows messages available in a given partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            def partition(topic_id, partition_id)
              @visibility_filter = ::Karafka::Web.config.ui.policies.messages
              @topic_id = topic_id
              @partition_id = partition_id
              @watermark_offsets = Models::WatermarkOffsets.find(topic_id, partition_id)
              @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

              previous_offset, @messages, next_offset = current_partition_data

              paginate(
                previous_offset,
                @params.current_offset,
                next_offset,
                # If message is an array, it means it's a compacted dummy offset representation
                @messages.map { |message| message.is_a?(Array) ? message.last : message.offset }
              )

              render
            end

            # Displays given message
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer] offset of the message we want to display
            # @param paginate [Boolean] do we want to have pagination
            def show(topic_id, partition_id, offset, paginate: true)
              Lib::PatternsDetector.new.call

              @visibility_filter = ::Karafka::Web.config.ui.policies.messages
              @topic_id = topic_id
              @partition_id = partition_id
              @offset = offset
              @message = Models::Message.find(@topic_id, @partition_id, @offset)

              @safe_key = Web::Pro::Ui::Lib::SafeRunner.new { @message.key }.tap(&:call)
              @safe_headers = Web::Pro::Ui::Lib::SafeRunner.new { @message.headers }.tap(&:call)
              @safe_payload = Web::Pro::Ui::Lib::SafeRunner.new { @message.payload }.tap(&:call)

              # This may be off for certain views like recent view where we are interested only
              # in the most recent all the time. It does not make any sense to display pagination
              # there
              if paginate
                # We need watermark offsets to decide if we can paginate left and right
                watermark_offsets = Models::WatermarkOffsets.find(topic_id, partition_id)
                paginate(offset, watermark_offsets.low, watermark_offsets.high)
              end

              render
            end

            # Displays the most recent message on a topic/partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer, nil] partition we're interested in or nil if we are
            #   interested in the most recent message from all the partitions
            def recent(topic_id, partition_id)
              if partition_id
                active_partitions = [partition_id]
              else
                partitions_count = Models::ClusterInfo.partitions_count(topic_id)
                active_partitions, = Paginators::Partitions.call(partitions_count, 1)
              end

              recent = nil

              # This selects first pages with most recent messages and moves to next if first
              # contains only compacted data, etc.
              #
              # We do it until we find a message we could refer to (if doable) within first
              # ten pages
              10.times do |page|
                messages, = Models::Message.topic_page(topic_id, active_partitions, page + 1)

                # Selects newest out of all partitions
                # Reject compacted messages and transaction-related once
                recent = messages.reject { |message| message.is_a?(Array) }.max_by(&:timestamp)

                break if recent
              end

              recent || not_found!

              show(topic_id, recent.partition, recent.offset, paginate: false)
            end

            # Computes a page on which the given offset is in the middle of the page (if possible)
            # Useful often when debugging to be able to quickly jump to the historical location
            # of message and its surrounding to understand failure
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer] offset of the message we want to display
            def surrounding(topic_id, partition_id, offset)
              watermark_offsets = Models::WatermarkOffsets.find(topic_id, partition_id)

              not_found! if offset < watermark_offsets.low
              not_found! if offset >= watermark_offsets.high

              # Assume we start from this offset
              shift = 0
              elements = 0

              # Position the offset as close to the middle of offset based page as possible
              ::Karafka::Web.config.ui.per_page.times do
                break if elements >= ::Karafka::Web.config.ui.per_page

                elements += 1 if offset + shift < watermark_offsets.high

                if offset - shift > watermark_offsets.low
                  shift += 1
                  elements += 1
                end
              end

              target = offset - shift

              redirect("explorer/#{topic_id}/#{partition_id}?offset=#{target}")
            end

            # Finds the closest offset matching the requested time and redirects to this location
            # Note, that it redirects to closest but always younger.
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param time [Time] time of the message
            def closest(topic_id, partition_id, time)
              target = Web::Ui::Lib::Admin.read_topic(topic_id, partition_id, 1, time).first

              partition_path = "explorer/#{topic_id}/#{partition_id}"
              partition_path += "?offset=#{target.offset}" if target

              redirect(partition_path)
            end

            private

            # Fetches current page data
            # @return [Array] fetched data with pagination information for the requested partition
            def current_partition_data
              Models::Message.offset_page(
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
