# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Aggregated health data statistics representation
        class Health
          class << self
            # @param state [State] current system state
            # @return [Hash] has with aggregated statistics
            def current(state)
              stats = {}

              iterate_partitions(state) do |process, consumer_group, topic, partition|
                cg_name = consumer_group.id
                t_name = topic.name
                pt_id = partition.id
                dispatched_at = process.dispatched_at

                ages = consumer_group[:subscription_groups].values.map do |sub_group_details|
                  rebalance_age = sub_group_details[:state][:rebalance_age] / 1_000
                  dispatched_at - rebalance_age
                end

                stats[cg_name] ||= { topics: {}, rebalance_ages: [] }
                stats[cg_name][:topics][t_name] ||= {}
                stats[cg_name][:topics][t_name][pt_id] = partition.to_h
                stats[cg_name][:topics][t_name][pt_id][:process] = process
                stats[cg_name][:rebalance_ages] += ages
              end

              stats.each_value do |details|
                details[:rebalanced_at] = details[:rebalance_ages].max
              end

              stats
            end

            private

            # Iterates over all partitions, yielding with extra expanded details
            #
            # @param state [State]
            def iterate_partitions(state)
              processes = Processes.active(state)

              processes.each do |process|
                process.consumer_groups.each do |consumer_group|
                  consumer_group.subscription_groups.each do |subscription_group|
                    subscription_group.topics.each do |topic|
                      topic.partitions.each do |partition|
                        yield(process, consumer_group, topic, partition)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
