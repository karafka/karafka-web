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
              #
              # @note Kafka returns group ids as binary strings, so we match on bytes and query
              #   further with the listed id. A non-ASCII UTF-8 id never completes a describe.
              def find(group_id)
                target = group_id.b

                listed = ::Karafka::Admin.list_consumer_groups.find do |group|
                  listed_id = group[:group_id]

                  next false unless listed_id.bytesize == target.bytesize

                  (listed_id.encoding == target.encoding) ? listed_id == target : listed_id.b == target
                end

                raise(Web::Errors::Ui::NotFoundError, group_id) unless listed

                new(::Karafka::Admin.describe_consumer_groups([listed[:group_id]]).first)
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
            # @return [Hash{String => Array<Hash>}] topics with partitions details (`:id`, `:lag`,
            #   `:stored_offset`), in alphabetical order
            def topics
              topics_names = Info.topics.map { |topic| topic[:topic_name] }

              return {} if topics_names.empty?

              lags = ::Karafka::Admin.read_lags_with_offsets({ id => topics_names }).fetch(id, {})

              lags
                .select { |_, partitions| partitions.any? { |_, details| details[:offset] >= 0 } }
                .sort_by(&:first)
                .to_h do |topic_name, partitions|
                  details = partitions.map do |partition_id, lag_with_offset|
                    {
                      id: partition_id,
                      lag: lag_with_offset.fetch(:lag),
                      stored_offset: lag_with_offset.fetch(:offset)
                    }
                  end

                  [topic_name, details]
                end
            end
          end
        end
      end
    end
  end
end
