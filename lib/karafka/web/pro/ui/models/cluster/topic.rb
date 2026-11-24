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
          module Cluster
            # Topic as the cluster metadata describes it, with its configs and messages distribution
            class Topic < Web::Ui::Lib::HashProxy
              class << self
                # @return [Array<Topic>] all topics in the cluster
                def all
                  Web::Ui::Models::Cluster::Info.fetch.topics.map do |topic|
                    new(topic)
                  end
                end

                # Finds requested topic
                #
                # @param topic_name [String] name of the topic
                # @return [Topic]
                # @raise [::Karafka::Web::Errors::Ui::NotFoundError] when the topic does not exist
                def find(topic_name)
                  new(Web::Ui::Lib::Admin.topic_info(topic_name))
                rescue Rdkafka::RdkafkaError => e
                  raise e unless e.code == :unknown_topic_or_part

                  raise(::Karafka::Web::Errors::Ui::NotFoundError, topic_name)
                end

                # @param topic_name [String] name of the topic
                # @return [Integer] number of partitions in a given topic
                # @raise [::Karafka::Web::Errors::Ui::NotFoundError] when the topic does not exist
                def partitions_count(topic_name)
                  find(topic_name).partition_count
                end
              end

              # @return [Array<Karafka::Admin::Configs::Config>] all topic configs
              def configs
                @configs ||= ::Karafka::Admin::Configs.describe(
                  ::Karafka::Admin::Configs::Resource.new(
                    type: :topic,
                    name: topic_name
                  )
                ).first.configs.dup
              end

              # Generates info about estimated messages distribution in partitions, allowing for
              # inspection and detection of imbalances
              #
              # @param partitions [Array<Integer>] partitions we're interested in
              #
              # @return [Array<HashProxy, Array<HashProxy>>] array where first value contains
              #   aggregated statistics and then the second value is an array with per partition
              #   data
              def distribution(partitions)
                sum = 0.0

                all_offsets = ::Karafka::Admin.read_watermark_offsets(topic_name => partitions)

                counts = partitions.map do |partition_id|
                  offsets = all_offsets.fetch(topic_name).fetch(partition_id)
                  count = offsets.last - offsets.first

                  sum += count

                  {
                    count: count,
                    partition_id: partition_id
                  }
                end

                avg = sum / counts.size

                counts.each do |part_stats|
                  count = part_stats[:count]

                  part_stats[:share] = ((count / sum) * 100).round(2)
                  part_stats[:diff] = ((count - avg) / avg) * 100
                end

                variance = counts
                  .map { |part_stats| part_stats[:count] }
                  .sum { |count| (count - avg)**2 } / counts.size

                std_dev = Math.sqrt(variance)
                std_dev_rel = ((std_dev / avg) * 100).round(2)

                [
                  # round stdev since its message count
                  Web::Ui::Lib::HashProxy.new(std_dev: std_dev.round, std_dev_rel: std_dev_rel, sum: sum),
                  counts.map { |part_stats| Web::Ui::Lib::HashProxy.new(part_stats) }
                ]
              end
            end
          end
        end
      end
    end
  end
end
