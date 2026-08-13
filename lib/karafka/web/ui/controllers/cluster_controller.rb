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

          # Cluster state should always be fresh and not from cache
          before { cache.clear }

          # Lists available brokers in the cluster
          def brokers
            @brokers = sort(Models::ClusterInfo.fetch.brokers)

            render
          end

          # List partitions replication details
          def replication
            @partitions, last_page = Paginators::Arrays.call(
              sort(replication_partitions),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end

          private

          # Flattens the displayable cluster topics into the flat partition rows the replication
          # table renders, sorts and paginates. Each row is a partition carrying its topic (and
          # topic name, so it can be sorted/filtered by name).
          #
          # @return [Array<Hash>] partition rows
          def replication_partitions
            displayable_topics.flat_map do |topic|
              topic[:partitions].map do |partition|
                partition.merge(
                  topic: topic,
                  topic_name: topic.fetch(:topic_name)
                )
              end
            end
          end

          # @return [Array<Hash>] cluster topics to display in an alphabetical order, with internal
          #   topics excluded unless the visibility config allows them
          def displayable_topics
            all = Models::ClusterInfo
              .fetch
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
