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
              partitions = topics.flat_map { |topic| topic[:partitions] }

              # Each partition has exactly one leader, so the partition count is also the total
              # number of leaderships to distribute across brokers
              total_leaderships = partitions.size
              total_replicas = partitions.sum { |partition| Array(partition[:replicas]).size }
              # Fair share of leaderships for a single broker in a perfectly balanced cluster
              even_leader_share = brokers.empty? ? 0.0 : 100.0 / brokers.size
              # Comparing a broker against the others is only meaningful with more than one broker
              # and at least one partition to distribute
              comparable = brokers.size >= 2 && total_leaderships.positive?

              brokers.map do |broker|
                leaderships = partitions.count { |partition| partition[:leader] == broker.id }
                replicas = partitions.count do |partition|
                  Array(partition[:replicas]).include?(broker.id)
                end
                in_sync = partitions.count do |partition|
                  Array(partition[:isrs]).include?(broker.id)
                end
                leader_share = percentage(leaderships, total_leaderships)

                new(
                  broker_id: broker.id,
                  broker_name: broker.name,
                  leader_count: leaderships,
                  leader_share: leader_share,
                  # A leader is always part of its own replica set, so replicas it does not lead are
                  # the ones it follows
                  follower_count: replicas - leaderships,
                  replica_count: replicas,
                  replica_share: percentage(replicas, total_replicas),
                  # Replicas this broker hosts that are not in-sync (a lagging/under-replicated
                  # replica on this node)
                  out_of_sync_count: replicas - in_sync,
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
