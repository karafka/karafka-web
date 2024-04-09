# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Aggregated health data statistics representation
        class Health
          class << self
            # @param state [State] current system state
            # @return [Hash] hash with aggregated statistics
            def current(state)
              stats = {}

              fetch_topics_data(state, stats)
              fetch_rebalance_ages(state, stats)

              sort_structure(stats)
            end

            # @return [Hash] hash with cluster lag data
            def cluster_lags_with_offsets
              # We need to remap raw results so they comply with our sorting flows
              mapped_lags = {}

              ::Karafka::Admin.read_lags_with_offsets(
                active_topics_only: Web.config.ui.visibility.active_topics_cluster_lags_only
              ).each do |consumer_group, topics|
                mapped_lags[consumer_group] ||= {}

                topics.each do |topic_name, partitions_details|
                  mapped_lags[consumer_group][topic_name] ||= []

                  partitions_details.each do |partition_id, lags_with_offsets|
                    mapped_lags[consumer_group][topic_name] << {
                      id: partition_id,
                      lag: lags_with_offsets.fetch(:lag),
                      stored_offset: lags_with_offsets.fetch(:offset)
                    }
                  end
                end
              end

              mapped_lags
            end

            private

            # Aggregates data on a per topic basis (in the context of a consumer group)
            # @param state [Hash]
            # @param stats [Hash] hash where we will store all the aggregated data
            def fetch_topics_data(state, stats)
              iterate_partitions(state) do |process, consumer_group, topic, partition|
                cg_name = consumer_group.id
                t_name = topic.name
                pt_id = partition.id

                stats[cg_name] ||= { topics: {} }
                stats[cg_name][:topics][t_name] ||= {}
                stats[cg_name][:topics][t_name][pt_id] = partition
                stats[cg_name][:topics][t_name][pt_id][:process] = process
              end
            end

            # Aggregates rebalances ages data
            # @param state [Hash]
            # @param stats [Hash] hash where we will store all the aggregated data
            def fetch_rebalance_ages(state, stats)
              iterate_partitions(state) do |process, consumer_group|
                cg_name = consumer_group.id
                dispatched_at = process.dispatched_at

                ages = consumer_group[:subscription_groups].values.map do |sub_group_details|
                  rebalance_age_ms = sub_group_details[:state][:rebalance_age] || 0
                  dispatched_at - rebalance_age_ms / 1_000
                end

                stats[cg_name][:rebalance_ages] ||= Set.new
                stats[cg_name][:rebalance_ages] += ages
              end

              stats.each_value do |details|
                details[:rebalanced_at] = details[:rebalance_ages].max
              end
            end

            # Iterates over all partitions, yielding with extra expanded details
            #
            # @param state [State]
            def iterate_partitions(state)
              # By default processes are sort by id and this is not what we want here
              # We want to make sure that the newest data is processed the last, so we get
              # the most accurate state in case of deployments and shutdowns, etc without the
              # expired processes partitions data overwriting the newly created processes
              processes = Processes.active(state).sort_by!(&:dispatched_at)

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

            # Sorts data so we always present it in an alphabetical order
            #
            # @param stats [Hash] stats hash
            # @return [Hash] sorted data
            def sort_structure(stats)
              # Ensure that partitions for all topics are in correct order
              # Ensure topics are in alphabetical order always
              stats.each_value do |cg_data|
                topics = cg_data[:topics]

                topics.each do |topic_name, t_data|
                  topics[topic_name] = Hash[t_data.sort_by { |key, _| key }]
                end

                cg_data[:topics] = Hash[topics.sort_by { |key, _| key }]
              end

              # Ensure that all consumer groups are always in the same order
              Hash[stats.sort_by { |key, _| key }]
            end
          end
        end
      end
    end
  end
end
