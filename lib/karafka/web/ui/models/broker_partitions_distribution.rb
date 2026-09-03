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
          # A broker leading more than this many times its fair share of partitions is flagged as
          # overloaded (fair share = an even split of all leaderships, i.e. 100% / broker count).
          OVERLOADED_RATIO = 1.5

          # A broker leading less than this fraction of its fair share of partitions is flagged as
          # underloaded.
          UNDERLOADED_RATIO = 0.5

          private_constant :OVERLOADED_RATIO, :UNDERLOADED_RATIO

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

              brokers.map do |broker|
                leaderships = partitions.count { |partition| partition[:leader] == broker.id }
                replicas = partitions.count do |partition|
                  Array(partition[:replicas]).include?(broker.id)
                end
                leader_share = percentage(leaderships, total_leaderships)

                new(
                  broker_id: broker.id,
                  broker_name: broker.name,
                  leader_count: leaderships,
                  leader_share: leader_share,
                  replica_count: replicas,
                  replica_share: percentage(replicas, total_replicas),
                  imbalance: imbalance(
                    leader_share, even_leader_share, brokers.size, total_leaderships
                  )
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

            # Classifies a broker's leadership load against an even split. Only meaningful with more
            # than one broker and at least one partition; otherwise every broker is `:balanced`.
            #
            # @param leader_share [Float] this broker's share of all leaderships
            # @param even_leader_share [Float] the fair (even) share
            # @param broker_count [Integer] number of brokers
            # @param total_leaderships [Integer] total partitions (leaderships) in the cluster
            # @return [Symbol] `:overloaded`, `:underloaded` or `:balanced`
            def imbalance(leader_share, even_leader_share, broker_count, total_leaderships)
              return :balanced if broker_count < 2 || total_leaderships.zero?
              return :overloaded if leader_share > even_leader_share * OVERLOADED_RATIO
              return :underloaded if leader_share < even_leader_share * UNDERLOADED_RATIO

              :balanced
            end
          end
        end
      end
    end
  end
end
