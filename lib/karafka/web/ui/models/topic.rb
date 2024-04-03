# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single topic data representation model
        class Topic < Lib::HashProxy
          class << self
            # @return [Array<Broker>] all topics in the cluster
            def all
              ClusterInfo.fetch.topics.map do |topic|
                new(topic)
              end
            end

            # Finds requested topic
            #
            # @param topic_name [String] name of the topic
            # @return [Topic]
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError]
            def find(topic_name)
              found = all.find { |topic| topic.topic_name == topic_name }

              return found if found

              raise(::Karafka::Web::Errors::Ui::NotFoundError, topic_name)
            end
          end

          # @return [Array<Partition>] All topic partitions data
          def partitions
            super.map do |partition_id, partition_hash|
              partition_hash[:partition_id] = partition_id

              Partition.new(partition_hash)
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
          #   aggregated statistics and then the second value is an array with per partition data
          def distribution(partitions)
            sum = 0.0
            avg = 0.0

            counts = partitions.map do |partition_id|
              offsets = Admin.read_watermark_offsets(topic_name, partition_id)
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
              Lib::HashProxy.new(std_dev: std_dev.round, std_dev_rel: std_dev_rel, sum: sum),
              counts.map { |part_stats| Lib::HashProxy.new(part_stats) }
            ]
          end
        end
      end
    end
  end
end
