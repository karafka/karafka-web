# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # A proxy between `::Karafka::Messages::Message` and web UI
        # We work with the Karafka messages but use this model to wrap the work needed.
        class Message
          extend Lib::Paginations::Paginators

          class << self
            # Looks for a message from a given topic partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer]
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError] when not found
            def find(topic_id, partition_id, offset)
              message = Lib::Admin.read_topic(
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

            # Fetches requested `page_count` number of Kafka messages starting from the oldest
            # requested `start_offset`. If `start_offset` is `-1`, will fetch the most recent
            # results
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param start_offset [Integer] oldest offset from which we want to get the data
            # @param watermark_offsets [Ui::Models::WatermarkOffsets] watermark offsets
            # @return [Array] We return page data as well as all the details needed to build
            #   the pagination details.
            def offset_page(topic_id, partition_id, start_offset, watermark_offsets)
              low_offset = watermark_offsets.low
              high_offset = watermark_offsets.high

              # If we start from offset -1, it means we want first page with the most recent
              # results. We obtain this page by using the offset based on the high watermark
              # off
              start_offset = high_offset - per_page if start_offset == -1

              # No previous pages, no data, and no more offsets
              no_data_result = [false, [], false]

              # If there is no data, we return the no results result
              return no_data_result if low_offset == high_offset

              if start_offset <= low_offset
                # If this page does not contain max per page, compute how many messages we can
                # fetch before stopping
                count = per_page - (low_offset - start_offset)
                next_offset = false
                start_offset = low_offset
              else
                next_offset = start_offset - per_page
                # Do not go below the lowest possible offset
                next_offset = low_offset if next_offset < low_offset
                count = high_offset - start_offset
                # If there would be more messages that we want to get, force max
                count = per_page if count > per_page
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

                previous_offset = start_offset + count

                if previous_offset >= high_offset
                  previous_offset = false
                elsif previous_offset + (per_page - 1) > high_offset
                  previous_offset = high_offset - per_page
                else
                  previous_offset
                end

                return [
                  previous_offset,
                  fill_compacted(messages, partition_id, context_offset, context_count, high_offset).reverse,
                  next_offset
                ]
              end

              no_data_result
            end

            # Fetches requested `page_count` number of Kafka messages from the topic partitions
            # and merges the results. Ensures, that pagination works as expected.
            #
            # @param topic_id [String]
            # @param partitions_ids [Array<Integer>] for which of the partitions we want to
            #   get the data. This is a limiting factor because of the fact that we have to
            #   query the watermark offsets independently
            # @param page [Integer] which page we want to get
            def topic_page(topic_id, partitions_ids, page)
              # This is the bottleneck, for each partition we make one request :(
              offsets = partitions_ids.map do |partition_id|
                [partition_id, Models::WatermarkOffsets.find(topic_id, partition_id)]
              end.to_h

              # Count number of elements we have in each partition
              # This assumes linear presence until low. If not, gaps will be filled like we fill
              # for per partition view
              counts = offsets.values.map { |offset| offset[:high] - offset[:low] }

              # Establish initial offsets for the iterator (where to start) per partition
              # We do not use the negative lookup iterator because we already can compute starting
              # offsets. This saves a lot of calls to Kafka
              ranges = Sets.call(counts, page).map do |partition_position, partition_range|
                partition_id = partitions_ids.to_a[partition_position]
                watermarks = offsets[partition_id]

                lowest = watermarks[:high] - partition_range.last - 1
                # We -1 because high watermark offset is the next incoming offset and not the last
                # one in the topic partition
                highest = watermarks[:high] - partition_range.first - 1

                # This range represents offsets we want to fetch
                [partition_id, lowest..highest]
              end.to_h

              # We start on our topic from the lowest offset for each expected partition
              iterator = Karafka::Pro::Iterator.new(
                { topic_id => ranges.transform_values(&:first) }
              )

              # Build the aggregated representation for each partition messages, so we can start
              # with assumption that all the topics are fully compacted. Then we can nicely replace
              # compacted `false` data with real messages, effectively ensuring that the gaps are
              # filled with `false` out-of-the-box
              aggregated = Hash.new { |h, k| h[k] = {} }

              # We initialize the hash so we have a constant ascending order based on the partition
              # number
              partitions_ids.each { |i| aggregated[i] }

              # We prefill all the potential offsets for each partition, so in case they were
              # compacted, we get a continuous flow
              ranges.each do |partition, range|
                partition_aggr = aggregated[partition]
                range.each { |i| partition_aggr[i] = [partition, i] }
              end

              # Iterate over all partitions and collect data
              iterator.each do |message|
                range = ranges[message.partition]

                # Do not fetch more data from a partition for which we got last message from the
                # expected offsets
                # When all partitions are stopped, we will stop operations. This drastically
                # improves performance because we no longer have to poll nils
                iterator.stop_current_partition if message.offset >= range.last

                partition = aggregated[message.partition]
                partition[message.offset] = message
              end

              [
                aggregated.values.map(&:values).map(&:reverse).reduce(:+),
                !Sets.call(counts, page + 1).empty?
              ]
            end

            private

            # @param args [Object] anything required by the admin `#read_topic`
            # @return [Array<Karafka::Messages::Message>, false] topic partition messages or false
            #   in case we hit a non-existing offset
            def read_topic(*args)
              Lib::Admin.read_topic(*args)
            rescue Rdkafka::RdkafkaError => e
              return false if e.code == :auto_offset_reset

              raise
            end

            # @return [Integer] elements per page
            def per_page
              ::Karafka::Web.config.ui.per_page
            end

            # Since we paginate with compacted offsets visible but we do not get compacted messages
            # we need to fill those with  just the missing offset and handle this on the UI.
            #
            # @param messages [Array<Karafka::Messages::Message>] selected messages
            # @param partition_id [Integer] number of partition for which we fill message gap
            # @param start_offset [Integer] offset of the first message (lowest) that we received
            # @param count [Integer] how many messages we wanted - we need that to fill spots to
            #   have exactly the number that was  requested and not more
            # @param high_offset [Integer] high watermark offset
            # @return [Array<Karafka::Messages::Message, Integer>] array with gaps filled with the
            #   missing offset
            def fill_compacted(messages, partition_id, start_offset, count, high_offset)
              filled = Array.new(count) do |index|
                messages.find do |message|
                  (message.offset - start_offset) == index
                end || [partition_id, start_offset + index]
              end

              # Remove dummies provisioned over the high offset
              filled.delete_if do |message|
                message.is_a?(Array) && message.last >= high_offset
              end

              filled
            end
          end
        end
      end
    end
  end
end
