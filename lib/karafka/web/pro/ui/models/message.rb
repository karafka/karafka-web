# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Models
          # Messages with the Pro reading flows, such as reading a page of all the topic partitions
          class Message < Web::Ui::Models::Message
            class << self
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
                offsets = partitions_ids.to_h do |partition_id|
                  [partition_id, Web::Ui::Models::Cluster::WatermarkOffsets.find(topic_id, partition_id)]
                end

                # Count number of elements we have in each partition
                # This assumes linear presence until low. If not, gaps will be filled like we fill
                # for per partition view
                counts = offsets.values.map { |offset| offset[:high] - offset[:low] }

                # Establish initial offsets for the iterator (where to start) per partition
                # We do not use the negative lookup iterator because we already can compute starting
                # offsets. This saves a lot of calls to Kafka
                ranges = Sets.call(counts, page).to_h do |partition_position, partition_range|
                  partition_id = partitions_ids.to_a[partition_position]
                  watermarks = offsets[partition_id]

                  lowest = watermarks[:high] - partition_range.last - 1
                  # We -1 because high watermark offset is the next incoming offset and not the last
                  # one in the topic partition
                  highest = watermarks[:high] - partition_range.first - 1

                  # This range represents offsets we want to fetch
                  [partition_id, lowest..highest]
                end

                # We start on our topic from the lowest offset for each expected partition
                iterator = ::Karafka::Pro::Iterator.new(
                  { topic_id => ranges.transform_values(&:first) }
                )

                # Build the aggregated representation for each partition messages, so we can start
                # with assumption that all the topics are fully compacted. Then we can nicely
                # replace compacted `false` data with real messages, effectively ensuring that the
                # gaps are filled with `false` out-of-the-box
                aggregated = Hash.new { |h, k| h[k] = {} }

                # We initialize the hash so we have a constant ascending order based on the
                # partition number
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
                  aggregated.values.sum([]) { |partition| partition.values.reverse },
                  !Sets.call(counts, page + 1).empty?
                ]
              end
            end
          end
        end
      end
    end
  end
end
