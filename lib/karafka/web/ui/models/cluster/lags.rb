# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Cluster
          # Committed offsets and lags of consumer groups as Kafka reports them, including groups
          # the Web UI does not receive reports from
          class Lags
            class << self
              # @return [Hash] lags of all the consumer groups with consumer groups and their
              #   topics in alphabetical order (mirroring {Health.current}), so both aggregated
              #   views share one stable default ordering. Raw cluster results arrive in whatever
              #   order the cluster reports them.
              def all
                # We need to remap raw results so they comply with our sorting flows
                mapped_lags = {}

                ::Karafka::Admin.read_lags_with_offsets(
                  active_topics_only: Web.config.ui.visibility.active_topics_cluster_lags_only
                ).each do |consumer_group, topics|
                  mapped_lags[consumer_group] ||= {}

                  topics.each do |topic_name, partitions_details|
                    mapped_lags[consumer_group][topic_name] ||= []

                    partitions_details.each do |partition_id, lag_with_offset|
                      mapped_lags[consumer_group][topic_name] << partition(
                        partition_id,
                        lag_with_offset
                      )
                    end
                  end
                end

                sort_structure(mapped_lags)
              end

              # @param partition_id [Integer]
              # @param lag_with_offset [Hash] partition `:lag` and `:offset` as Kafka reports them
              # @return [Hash] partition `:id`, `:lag` and `:stored_offset`
              def partition(partition_id, lag_with_offset)
                {
                  id: partition_id,
                  lag: lag_with_offset.fetch(:lag),
                  stored_offset: lag_with_offset.fetch(:offset)
                }
              end

              private

              # Sorts the lags structure (`cg => topic_name => partitions`) so consumer groups and
              # their topics are in alphabetical order and each topic's partitions are in partition
              # id order, giving this lens the same stable default order {Health.current} gives
              # the report-based tree.
              #
              # @param stats [Hash] cluster lags hash
              # @return [Hash] sorted data
              #
              # @note Partitions are an Array of `{ id:, lag:, stored_offset: }` hashes here, not
              #   the id-keyed Hash the report-based tree uses, so they are sorted on `:id` and
              #   stay an Array - {Health::ClusterLagsAggregation} and the partitions controller
              #   both expect one.
              def sort_structure(stats)
                sorted = {}

                stats.sort_by { |consumer_group, _| consumer_group }.each do |consumer_group, topics|
                  sorted_topics = topics.sort_by { |topic_name, _| topic_name }.to_h

                  sorted_topics.each do |topic_name, partitions|
                    sorted_topics[topic_name] = partitions.sort_by { |partition| partition[:id] }
                  end

                  sorted[consumer_group] = sorted_topics
                end

                sorted
              end
            end
          end
        end
      end
    end
  end
end
