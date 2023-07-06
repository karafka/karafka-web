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

            # Fetches requested `page_count` number of Kafka messages starting from the oldest
            # requested `start_offset`. If `start_offset` is `-1`, will fetch the most recent
            # results
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param start_offset [Integer] oldest offset from which we want to get the data
            # @param low_offset [Integer] low watermark offset
            # @param high_offset [Integer] high watermark offset
            # @return [Array] We return page data as well as all the details needed to build
            #   the pagination details.
            def offset_page(topic_id, partition_id, start_offset, low_offset, high_offset)
              partitions_count = fetch_partition_count(topic_id)

              # If we start from offset -1, it means we want first page with the most recent
              # results. We obtain this page by using the offset based on the high watermark
              # off
              start_offset = high_offset - per_page if start_offset == -1

              # No previous pages, no data, and no more offsets
              no_data_result = [false, [], false, partitions_count]

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

                return [
                  # If there is a potential previous page with more recent data, compute its
                  # offset
                  previous_offset >= high_offset ? false : previous_offset,
                  fill_compacted(messages, context_offset, context_count).reverse,
                  next_offset,
                  partitions_count
                ]
              end

              no_data_result
            end

            # Fetches requested `page_count` number of Kafka messages from all the topic partitions
            # and merges the results. Ensures, that pagination works as expected.
            #
            # @param topic_id [String]
            # @param page [Integer] which page we want to get
            # @param partitions_count [Integer] how many partitions do we have in this topic
            def topic_page(topic_id, page, partitions_count)
              # For topics with a lot of partitions we cannot get all the data efficiently, that
              # is why we limit number of partitions by default
              if partitions_count > max_aggregable_partitions
                max_partitions = max_aggregable_partitions
                limited = true
              else
                max_partitions = partitions_count
                limited = false
              end

              # This is the bottleneck, for each partition we make one request :(
              offsets = Array.new(max_partitions) do |partition|
                [partition, Models::WatermarkOffsets.find(topic_id, partition)]
              end.to_h

              # Count number of elements we have in each partition
              # This assumes linear presence until low. If not, gaps will be filled like we fill
              # for per partition view
              counts = offsets.values.map { |offset| offset[:high] - offset[:low] }

              # Establish initial offsets for the iterator (where to start) per partition
              # We do not use the negative lookup iterator because we already can compute starting
              # offsets. This saves a lot of calls to Kafka
              ranges = elements_for_page(page, counts)
                       .map { |a| [a[:partition], offsets[a[:partition]][:high] - a[:indices].last] }
                       .to_h

              # Figure out how many elements we want to get at most per each partition
              limits = elements_for_page(page, counts)
                       .map { |a| [a[:partition], a[:indices].size] }
                       .to_h

              iterator = Karafka::Pro::Iterator.new({ topic_id => ranges })

              # Build the aggregated representation for each partition messages, so we can start
              # with assumption that all the topics are fully compacted. Then we can nicely replace
              # compacted `false` data with real messages, effectively ensuring that the gaps are
              # filled with `false` out-of-the-box
              aggregated = Hash.new { |h, k| h[k] = {} }

              # We initialize the hash so we have a constant ascending order based on the partition
              # number
              partitions_count.times { |i| aggregated[i] }

              # We prefill all the potential offsets for each partition, so in case they were
              # compacted, we get a continuous flow
              limits.each do |partition, limit|
                start = ranges[partition]

                limit.times.each do |i|
                  aggregated[partition][start + i] = start + i
                end
              end

              # Iterate over all partitions and collect data
              iterator.each do |message|
                partition = aggregated[message.partition]
                partition[message.offset] = message

                # Since we may be getting more data because of incoming messages, we need to make
                # sure that we stop when we've got as much as we needed per each partition
                iterator.stop_current_partition if partition.count >= limits[message.partition]
              end

              [
                aggregated.values.map(&:values).map(&:reverse).reduce(:+),
                !elements_for_page(page + 1, counts).empty?,
                limited
              ]
            end

            private

            # Figures out how many elements and from which partition should we get on a given page
            # It takes into consideration cases where we have more partitions than per page
            # elements
            # @param page_number [Integer] page number (starts with 1)
            # @param counts [Array<Integer>] array with count of messages in each partition
            # @return [Hash<Integer, Range>] hash with per-partition details on which elements
            #   should be taken. It returns values starting from 0 and this needs to be reverse
            #   converted against watermark offsets
            def elements_for_page(page_number, counts)
              total_elements = counts.sum
              first_global_index = (page_number - 1) * per_page
              last_global_index = [first_global_index + per_page, total_elements].min

              set_indices_map = Hash.new { |h, k| h[k] = [] }

              (first_global_index...last_global_index).each do |global_index|
                set_index = global_index % counts.size
                element_index = global_index / counts.size
                set_indices_map[set_index] << element_index if element_index < counts[set_index]
              end

              set_indices_map.map do |partition, indices|
                {
                  partition: partition,
                  indices: indices.min...indices.max + 1
                }
              end
            end

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

            # @return [Integer] how many partitions data at most we can aggregate
            def max_aggregable_partitions
              Karafka::Web.config.ui.explorer.max_aggregable_partitions
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
