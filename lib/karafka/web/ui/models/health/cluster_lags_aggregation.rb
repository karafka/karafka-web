# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Health
          # Collapses the cluster lags from {Health.cluster_lags_with_offsets} into a single
          # {AggregatedClusterTopic} summary per topic, for the per-topic cluster lags view. The
          # `cg => topic_name` tree shape is preserved so the existing filtering flow keeps working.
          class ClusterLagsAggregation
            class << self
              # @return [Hash] hash with per-topic aggregated cluster lag data
              def call
                stats = Health.cluster_lags_with_offsets

                aggregated = {}

                # Present consumer groups and their topics in alphabetical order, consistent with
                # the topics view (which inherits this ordering from `.current`'s `sort_structure`).
                # The raw cluster lags come back in whatever order the cluster reports them.
                stats.sort_by { |consumer_group, _| consumer_group }.each do |consumer_group, topics|
                  aggregated[consumer_group] = topics
                    .sort_by { |topic_name, _| topic_name }
                    .each_with_object({}) do |(topic_name, partitions), sorted_topics|
                      sorted_topics[topic_name] = AggregatedClusterTopic.new(topic_name, partitions)
                    end
                end

                aggregated
              end
            end
          end
        end
      end
    end
  end
end
