# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Health
          # Collapses the cluster lags from {Cluster::Lags.all} into a single
          # {AggregatedClusterTopic} summary per topic, for the per-topic cluster lags view. The
          # `cg => topic_name` tree shape (and its ordering) is preserved so the existing filtering
          # and sorting flows keep working.
          class ClusterLagsAggregation
            class << self
              # @return [Hash] hash with per-topic aggregated cluster lag data
              def call
                stats = Cluster::Lags.all

                stats.each_value do |topics|
                  topics.each do |topic_name, partitions|
                    topics[topic_name] = AggregatedClusterTopic.new(topic_name, partitions)
                  end
                end

                stats
              end
            end
          end
        end
      end
    end
  end
end
