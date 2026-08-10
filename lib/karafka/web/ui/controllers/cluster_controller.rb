# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Selects cluster info and topics basic info
        class ClusterController < BaseController
          self.sortable_attributes = %w[
            broker_id
            broker_name
            broker_port
            topic_name
            partition_id
            leader
            replica_count
            in_sync_replica_brokers
          ].freeze

          # Each action renders different columns, so we scope the filterable fields per action to
          # Cluster state should always be fresh and not from cache
          before { cache.clear }

          # Lists available brokers in the cluster
          def brokers
            @brokers = sort(cluster_info.brokers)

            render
          end

          # List partitions replication details
          def replication
            paginate_partitions(replication_partitions)

            render
          end

          private

          # Flattens the cluster topics into a single list of partition rows, each carrying its
          # topic (and topic name, for sorting).
          #
          # @return [Array<Hash>] partition rows
          def replication_partitions
            partitions_total = []

            displayable_topics(cluster_info).each do |topic|
              topic[:partitions].each do |partition|
                partitions_total << partition.merge(
                  topic: topic,
                  # Will allow sorting by name
                  topic_name: topic.fetch(:topic_name)
                )
              end
            end

            partitions_total
          end

          # Sorts and paginates the partition rows into `@partitions`. This is the seam a Pro
          # subclass overrides to also apply filtering (a Pro-only feature); OSS only sorts.
          #
          # @param partitions_total [Array<Hash>] partition rows
          def paginate_partitions(partitions_total)
            @partitions, last_page = Paginators::Arrays.call(
              sort(partitions_total),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)
          end

          # @return [Array] whole cluster info
          def cluster_info
            @cluster_info ||= Models::ClusterInfo.fetch
          end

          # @param cluster_info [Rdkafka::Metadata] cluster metadata
          # @return [Array<Hash>] array with topics to be displayed sorted in an alphabetical
          #   order
          def displayable_topics(cluster_info)
            all = cluster_info
              .topics
              .sort_by { |topic| topic[:topic_name] }

            return all if ::Karafka::Web.config.ui.visibility.internal_topics

            all.reject { |topic| topic[:topic_name].start_with?("__") }
          end
        end
      end
    end
  end
end
