# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Health
          # Aggregates the per-partition cluster lag data of a single topic (within a consumer
          # group) into a topic-level summary, so the cluster lags view can show one row per topic
          # instead of one row per partition.
          #
          # Unlike {AggregatedTopic}, the cluster lags come straight from Kafka
          # ({Health.cluster_lags_with_offsets}) as plain `{ id:, lag:, stored_offset: }` hashes, so
          # there is no LSO risk state, poll state or freeze-duration data here - only lag.
          #
          # It is a {Lib::HashProxy} (like {AggregatedTopic}) so it stays a filterable/"prunable"
          # leaf in the cluster lags tree and the keyword filter keeps matching on topic name keys.
          class AggregatedClusterTopic < Lib::HashProxy
            include LagStats

            # @param name [String] topic name (stored so the aggregated rows can be sorted by it)
            # @param partitions [Array<Hash>] cluster lag entries for the topic, each a hash with
            #   `:id`, `:lag` and `:stored_offset`
            def initialize(name, partitions)
              # Negative lag means the topic was never consumed by the group, so it is excluded
              measurable = partitions.select { |partition| partition[:lag] >= 0 }
              lags = measurable.map { |partition| partition[:lag] }
              worst_lag_partition = measurable.max_by { |partition| partition[:lag] }

              super(
                name: name,
                partitions_count: partitions.size,
                measurable_count: lags.size,
                lag: lags.empty? ? -1 : lags.sum,
                max_lag: lags.max || -1,
                avg_lag: lags.empty? ? -1 : (lags.sum.to_f / lags.size).round,
                # -1 (not a valid partition id) when no partition has a lag. `HashProxy` treats a nil
                # value as "not found", so a sentinel is used rather than nil.
                max_lag_partition_id: worst_lag_partition ? worst_lag_partition[:id] : -1
              )
            end
          end
        end
      end
    end
  end
end
