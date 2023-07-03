# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # A proxy between `::Karafka::Messages::Message` and web UI
        # We work with the Karafka messages but use this model to wrap the work needed.
        class Message
          class << self
            # Looks for a message from a given topic partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer]
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError] when not found
            def find(topic_id, partition_id, offset)
              message = Karafka::Admin.read_topic(
                topic_id,
                partition_id,
                1,
                offset
              ).first

              return message if message

              raise(
                ::Karafka::Web::Errors::Ui::NotFoundError,
                [topic_id, partition_id, offset].join(', ')
              )
            end

            # Fetches requested page of Kafka messages.
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param page [Integer]
            # @return [Array] We return both page data as well as all the details needed to build
            #   the pagination details.
            def page(topic_id, partition_id, page)
              low_offset, high_offset = Karafka::Admin.read_watermark_offsets(
                topic_id,
                partition_id
              )

              partitions_count = fetch_partition_count(topic_id)

              no_data_result = [[], true, partitions_count]

              # If there is not even one message, we need to early exit
              # If low and high watermark offsets are of the same value, it means no data in the
              # topic is present
              return no_data_result if low_offset == high_offset

              # We add plus one because we compute previous offset from which we want to start and
              # not previous page leading offset
              start_offset = high_offset - (per_page * page)

              if start_offset <= low_offset
                count = per_page - (low_offset - start_offset)
                last_page = true
                start_offset = low_offset
              else
                last_page = false
                count = per_page
              end

              # This code is a bit tricky. Since topics can be compacted and certain offsets may
              # not be present at all, it may happen that we want to read from a non-existing
              # offset. In case like this we need to catch this error (we do it in `read_topic`)
              # and we need to move to an offset closer to high offset. This is not fast but it is
              # an edge case that should not happen often when inspecting real time data. This can
              # happen more often for heavily compacted topics with short retention but even then
              # it is ok for 25 elements we usually operate on a single page.
              count.times do |index|
                context_offset = start_offset + index
                # We need to get less if we move up with missing offsets to get exactly
                # the number we needed
                context_count = count - index

                messages = read_topic(
                  topic_id,
                  partition_id,
                  context_count,
                  context_offset,
                  # We do not reset the offset here because we are not interested in seeking from
                  # any offset. We are interested in the indication, that there is no offset of a
                  # given value so we can try with a more recent one
                  'auto.offset.reset': 'error'
                )

                next unless messages

                return [
                  fill_compacted(messages, context_offset, context_count).reverse,
                  last_page,
                  partitions_count
                ]
              end

              no_data_result
            end

            private

            # @param args [Object] anything required by the admin `#read_topic`
            # @return [Array<Karafka::Messages::Message>, false] topic partition messages or false
            #   in case we hit a non-existing offset
            def read_topic(*args)
              ::Karafka::Admin.read_topic(*args)
            rescue Rdkafka::RdkafkaError => e
              return false if e.code == :auto_offset_reset

              raise
            end

            # @param topic_id [String] id of the topic
            # @return [Integer] number of partitions this topic has
            def fetch_partition_count(topic_id)
              ::Karafka::Admin
                .cluster_info
                .topics
                .find { |topic| topic[:topic_name] == topic_id }
                .fetch(:partition_count)
            end

            # @return [Integer] elements per page
            def per_page
              ::Karafka::Web.config.ui.per_page
            end

            # Since we paginate with compacted offsets visible but we do not get compacted messages
            # we need to fill those with  just the missing offset and handle this on the UI.
            #
            # @param messages [Array<Karafka::Messages::Message>] selected messages
            # @param start_offset [Integer] offset of the first message (lowest) that we received
            # @param count [Integer] how many messages we wanted - we need that to fill spots to
            #   have exactly the number that was  requested and not more
            # @return [Array<Karafka::Messages::Message, Integer>] array with gaps filled with the
            #   missing offset
            def fill_compacted(messages, start_offset, count)
              Array.new(count) do |index|
                messages.find do |message|
                  (message.offset - start_offset) == index
                end || start_offset + index
              end
            end
          end
        end
      end
    end
  end
end
