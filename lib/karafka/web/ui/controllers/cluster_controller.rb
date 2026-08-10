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
              sort(Models::ClusterInfo.partitions),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end
        end
      end
    end
  end
end
