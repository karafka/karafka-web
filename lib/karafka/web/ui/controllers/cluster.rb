# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Selects cluster info and topics basic info
        class Cluster < Base
          # List cluster info data
          def index
            # Make sure, that for the cluster view we always get the most recent cluster state
            @cluster_info = Models::ClusterInfo.fetch(cached: false)

            partitions_total = []

            displayable_topics(@cluster_info).each do |topic|
              topic[:partitions].each do |partition|
                partitions_total << partition.merge(topic: topic)
              end
            end

            @partitions, last_page = Ui::Lib::Paginations::Paginators::Arrays.call(
              partitions_total,
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end

          private

          # @param cluster_info [Rdkafka::Metadata] cluster metadata
          # @return [Array<Hash>] array with topics to be displayed sorted in an alphabetical
          #   order
          def displayable_topics(cluster_info)
            all = cluster_info
                  .topics
                  .sort_by { |topic| topic[:topic_name] }

            return all if ::Karafka::Web.config.ui.show_internal_topics

            all.reject { |topic| topic[:topic_name].start_with?('__') }
          end
        end
      end
    end
  end
end
