# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Rolls the cluster metadata up into a per-broker partition distribution: how many
        # partitions each broker leads and how many partition replicas it hosts, plus each broker's
        # share of the total. It surfaces load imbalance across brokers (one node leading far more
        # partitions than the rest) without any external tooling.
        #
        # It is read-only - it only aggregates {ClusterInfo} data, so it adds no tracking overhead.
        class BrokerPartitionsDistribution < Lib::HashProxy
          class << self
            # @param brokers [Array<Broker>] cluster brokers
            # @param topics [Array<Hash>] cluster topics, each with a `:partitions` array whose
            #   entries carry `:leader` (broker id) and `:replicas` (array of broker ids)
            # @return [Array<BrokerPartitionsDistribution>] one row per broker, in the given
            #   brokers order
            def all(brokers:, topics:)
              # Single pass over every partition, tallying per broker id so we don't rescan the
              # partition list once per broker (which would be O(brokers x partitions)). All the
              # follower/out-of-sync tallies are counted only for partitions the broker actually
              # replicates, so no derived count can ever go negative on odd/older metadata.
              leaders = Hash.new(0)
              replicas = Hash.new(0)
              followers = Hash.new(0)
              out_of_sync = Hash.new(0)
              total_leaderships = 0
              total_replicas = 0

              topics.each do |topic|
                topic[:partitions].each do |partition|
                  leader = partition[:leader]
                  partition_isrs = Array(partition[:isrs])

                  total_leaderships += 1
                  leaders[leader] += 1

                  Array(partition[:replicas]).each do |broker_id|
                    total_replicas += 1
                    followers[broker_id] += 1 unless broker_id == leader
                    out_of_sync[broker_id] += 1 unless partition_isrs.include?(broker_id)
                    replicas[broker_id] += 1
                  end
                end
              end

              # Fair share of leaderships for a single broker in a perfectly balanced cluster
              even_leader_share = brokers.empty? ? 0.0 : 100.0 / brokers.size
              # Comparing a broker against the others is only meaningful with more than one broker
              # and at least one partition to distribute
              comparable = brokers.size >= 2 && total_leaderships.positive?

              brokers.map do |broker|
                leader_share = percentage(leaders[broker.id], total_leaderships)

                new(
                  broker_id: broker.id,
                  broker_name: broker.name,
                  leader_count: leaders[broker.id],
                  leader_share: leader_share,
                  # Replicas this broker hosts but does not lead
                  follower_count: followers[broker.id],
                  replica_count: replicas[broker.id],
                  replica_share: percentage(replicas[broker.id], total_replicas),
                  # Replicas this broker hosts that are not in-sync (a lagging/under-replicated
                  # replica on this node)
                  out_of_sync_count: out_of_sync[broker.id],
                  # How many times this broker's fair share of leaderships it actually leads (1.0 is
                  # perfectly even). The over/under-loaded thresholds live in the Pro config and are
                  # applied by the view, so this stays a plain, config-free metric.
                  load_ratio: comparable ? (leader_share / even_leader_share).round(2) : 1.0,
                  comparable: comparable
                )
              end
            end

            # Lists the individual partitions assigned to a single broker (the drill-down behind a
            # distribution row), each with the broker's role on it and whether its replica is
            # in-sync.
            #
            # @param broker_id [Integer] broker to list assignments for
            # @param topics [Array<Hash>] cluster topics (see {.all})
            # @return [Array<Lib::HashProxy>] assignment rows with `topic_name`, `partition_id`,
            #   `role` (`:leader`/`:follower`) and `in_sync`
            def partitions_for(broker_id:, topics:)
              assignments = []

              topics.each do |topic|
                topic[:partitions].each do |partition|
                  next unless Array(partition[:replicas]).include?(broker_id)

                  assignments << Lib::HashProxy.new(
                    topic_name: topic[:topic_name],
                    partition_id: partition[:partition_id],
                    role: (partition[:leader] == broker_id) ? :leader : :follower,
                    in_sync: Array(partition[:isrs]).include?(broker_id)
                  )
                end
              end

              assignments
            end

            private

            # @param count [Integer] this broker's count
            # @param total [Integer] total across all brokers
            # @return [Float] percentage share (0.0 when there is nothing to distribute)
            def percentage(count, total)
              return 0.0 if total.zero?

              (count / total.to_f * 100).round(2)
            end
          end
        end
      end
    end
  end
end
