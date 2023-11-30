# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Selects cluster info and topics basic info
        class Cluster < Base
          # Lists available brokers in the cluster
          def brokers
            @brokers = refine(cluster_info.brokers)

            render
          end

          # List topics and partitions with details
          def topics
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

            @partitions, last_page = Ui::Lib::Paginations::Paginators::Arrays.call(
              refine(partitions_total),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end

          private

          # Make sure, that for the cluster view we always get the most recent cluster state
          def cluster_info
            @cluster_info ||= Models::ClusterInfo.fetch(cached: false)
          end

          # @param cluster_info [Rdkafka::Metadata] cluster metadata
          # @return [Array<Hash>] array with topics to be displayed sorted in an alphabetical
          #   order
          def displayable_topics(cluster_info)
            all = cluster_info
                  .topics
                  .sort_by { |topic| topic[:topic_name] }

            return all if ::Karafka::Web.config.ui.visibility.internal_topics

            all.reject { |topic| topic[:topic_name].start_with?('__') }
          end
        end
      end
    end
  end
end
