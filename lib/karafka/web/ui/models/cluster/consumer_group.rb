# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Cluster
          # Representation of a consumer group as the cluster sees it, regardless of whether it is
          # managed or reported by Karafka. Covers groups of other (also non-Ruby) applications,
          # applications that are down and leftover empty groups.
          class ConsumerGroup < Lib::HashProxy
            class << self
              # @return [Array<ConsumerGroup>] all consumer groups in the cluster with their
              #   state only, sorted by id
              def all
                ::Karafka::Admin
                  .list_consumer_groups
                  .sort_by { |group| group[:group_id] }
                  .map { |group| new(group) }
              end

              # @param group_id [String] consumer group id
              # @return [ConsumerGroup] described consumer group with its members
              # @raise [Web::Errors::Ui::NotFoundError] when the cluster has no such group
              def find(group_id)
                listed_id = kafka_id(group_id)

                raise(Web::Errors::Ui::NotFoundError, group_id) unless listed_id

                new(::Karafka::Admin.describe_consumer_groups([listed_id]).first)
              end

              # @param group_id [String] consumer group id
              # @return [String, nil] id of the group to query Kafka with or nil when the cluster
              #   has no such group
              #
              # @note Kafka returns group ids as binary strings, so we match on bytes and query
              #   further with the listed id. A non-ASCII UTF-8 id never completes a describe.
              def kafka_id(group_id)
                target = group_id.b

                ::Karafka::Admin
                  .list_consumer_groups
                  .find { |group| group[:group_id].b == target }
                  &.fetch(:group_id)
              end
            end

            # @return [String] consumer group id
            def id
              @hash[:group_id]
            end

            # @return [Array<Hash>] members of the group, empty for groups that are not described
            def members
              @hash.fetch(:members, [])
            end

            # Reads the committed offsets and lags of this group. Kafka cannot list the topics a
            # group committed offsets for, so we query all the cluster topics and keep only those
            # with at least one committed offset.
            #
            # @return [Array<Hash>] partitions of those topics (`:topic_name`, `:id`, `:lag`,
            #   `:stored_offset`), ordered by topic name and partition
            def offsets
              topics_names = Info.topics.map { |topic| topic[:topic_name] }

              return [] if topics_names.empty?

              lags = ::Karafka::Admin.read_lags_with_offsets({ id => topics_names }).fetch(id, {})

              lags
                .select { |_, partitions| partitions.any? { |_, details| details[:offset] >= 0 } }
                .sort_by(&:first)
                .flat_map do |topic_name, partitions|
                  partitions.sort_by(&:first).map do |partition_id, lag_with_offset|
                    { topic_name: topic_name, **Lags.partition(partition_id, lag_with_offset) }
                  end
                end
            end
          end
        end
      end
    end
  end
end
