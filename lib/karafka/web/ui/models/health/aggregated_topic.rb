# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Health
          # Aggregates the per-partition health data of a single topic (within a consumer group)
          # into a topic-level summary, so the health view can show one row per topic instead of
          # one row per partition.
          #
          # It wraps the `{ partitions:, partitions_count: }` node produced by {Health.current} and
          # rolls the partition metrics up. Negative metric values mean "not available (yet)" (see
          # {Partition}), so they are excluded from the sums and surfaced as `-1`/`N/A` when nothing
          # is available.
          #
          # It is a {Lib::HashProxy} (like {Partition}) so it stays a filterable/"prunable" leaf in
          # the health stats tree: the keyword filter treats the topics map as a structural
          # container and matches on the topic name keys, exactly like the per-partition overview.
          class AggregatedTopic < Lib::HashProxy
            include LagStats

            # Ordering used to pick the "worst" LSO risk state across partitions. A single stopped
            # partition should dominate the whole topic summary.
            LSO_RISK_STATES_SEVERITY = {
              active: 0,
              at_risk: 1,
              stopped: 2
            }.freeze

            private_constant :LSO_RISK_STATES_SEVERITY

            # @param name [String] topic name (stored so the aggregated rows can be sorted by it)
            # @param topic_details [Hash] a single topic node from {Health.current}, that is a hash
            #   with `:partitions` (id => {Partition}) and `:partitions_count` keys
            def initialize(name, topic_details)
              partitions_map = topic_details[:partitions]
              partitions = partitions_map.values
              partitions_count = topic_details[:partitions_count]
              # Negative lag means "not available yet", so it is excluded from every roll-up
              measurable = partitions.select { |partition| partition.lag_hybrid >= 0 }
              lags = measurable.map(&:lag_hybrid)
              worst_lag_partition = measurable.max_by(&:lag_hybrid)

              super(
                name: name,
                partitions_count: partitions_count,
                present_count: partitions.size,
                # Partitions that were assigned/expected (ids below the reported count) but have no
                # data. Computed exactly like the `_partitions_with_fallback` "No data available"
                # rows, so the aggregated count matches what the drill-down shows. Note that the
                # reported count is a per-process assignment count, so `present_count` can legitimately
                # exceed it (data merged across processes) - hence a dedicated missing count rather
                # than a present/total ratio.
                no_data_count: (0...partitions_count).count { |id| !partitions_map.key?(id) },
                measurable_count: lags.size,
                lag_hybrid: lags.empty? ? -1 : lags.sum,
                lag_hybrid_d: measurable.sum(&:lag_hybrid_d),
                max_lag: lags.max || -1,
                avg_lag: lags.empty? ? -1 : (lags.sum.to_f / lags.size).round,
                # -1 (not a valid partition id) when no partition has a lag yet. `HashProxy` treats a
                # nil value as "not found", so a sentinel is used rather than nil.
                max_lag_partition_id: worst_lag_partition ? worst_lag_partition.id : -1,
                lso_risk_state: worst_lso_risk_state(partitions),
                paused_count: partitions.count { |partition| partition.poll_state != "active" }
              )
            end

            # @return [Boolean] true when there is anything worth a closer look: a non-active LSO
            #   risk state, any paused partition or partitions with no data
            def unhealthy?
              lso_risk_state != :active ||
                paused_count.positive? ||
                no_data_count.positive?
            end

            private

            # @param partitions [Array<Partition>] all partitions of the topic
            # @return [Symbol] the worst LSO risk state across the partitions (defaults to `:active`
            #   when there are no partitions). Named `lso_risk_state` on the instance (via the stored
            #   hash) so the `lso_risk_state_bg`/`lso_risk_state_badge` helpers work unchanged.
            def worst_lso_risk_state(partitions)
              partitions
                .map(&:lso_risk_state)
                .max_by { |state| LSO_RISK_STATES_SEVERITY.fetch(state) } || :active
            end
          end
        end
      end
    end
  end
end
