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

              brokers.map do |broker|
                leaderships = partitions.count { |partition| partition[:leader] == broker.id }
                replicas = partitions.count do |partition|
                  Array(partition[:replicas]).include?(broker.id)
                end

                new(
                  broker_id: broker.id,
                  broker_name: broker.name,
                  leader_count: leaderships,
                  leader_share: percentage(leaderships, total_leaderships),
                  replica_count: replicas,
                  replica_share: percentage(replicas, total_replicas)
                )
              end
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
