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

            # Builds the same tree as {.current} but with each topic collapsed into a single
            # {AggregatedTopic} summary instead of its per-partition data. Used by the per-topic
            # health view where each topic is a single row. The consumer group level (including
            # `:rebalanced_at`) and the `cg => :topics => topic_name` shape are preserved, so the
            # existing sorting and filtering flows keep working unchanged.
            #
            # @param state [State] current system state
            # @return [Hash] hash with per-topic aggregated statistics
            def aggregated(state)
              stats = current(state)

              stats.each_value do |cg_details|
                cg_details[:topics].each do |topic_name, topic_details|
                  cg_details[:topics][topic_name] = AggregatedTopic.new(topic_name, topic_details)
                end
              end

              stats
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

            # Same data as {.cluster_lags_with_offsets} but with each topic collapsed into a single
            # {AggregatedClusterTopic} summary instead of its per-partition array. Used by the
            # per-topic cluster lags view. The `cg => topic_name` tree shape is preserved so the
            # existing filtering flow keeps working.
            #
            # @return [Hash] hash with per-topic aggregated cluster lag data
            def aggregated_cluster_lags
              stats = cluster_lags_with_offsets

              aggregated = {}

              # Present consumer groups and their topics in alphabetical order, consistent with the
              # topics view (which inherits this ordering from `.current`'s `sort_structure`). The
              # raw cluster lags come back in whatever order the cluster reports them.
              stats.sort_by { |consumer_group, _| consumer_group }.each do |consumer_group, topics|
                aggregated[consumer_group] = topics
                  .sort_by { |topic_name, _| topic_name }
                  .each_with_object({}) do |(topic_name, partitions), sorted_topics|
                    sorted_topics[topic_name] = AggregatedClusterTopic.new(topic_name, partitions)
                  end
              end

              aggregated
            end

            private

            # Aggregates data on a per topic basis (in the context of a consumer group)
            # @param state [Hash]
            # @param stats [Hash] hash where we will store all the aggregated data
            def fetch_topics_data(state, stats)
              iterate_partitions(state) do |process, consumer_group, subscription_group, topic, partition|
                cg_id = consumer_group.id
                sg_id = subscription_group.id
                t_name = topic.name
                pt_id = partition.id

                stats[cg_id] ||= { topics: {} }

                stats[cg_id][:topics][t_name] ||= {
                  partitions: {},
                  partitions_count: topic.partitions_cnt
                }

                stats[cg_id][:topics][t_name][:partitions][pt_id] = partition
                stats[cg_id][:topics][t_name][:partitions][pt_id][:process] = process
                stats[cg_id][:topics][t_name][:partitions][pt_id][:subscription_group_id] = sg_id
                stats[cg_id][:topics][t_name][:partitions][pt_id][:instance_id] = subscription_group.instance_id
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
                  dispatched_at - (rebalance_age_ms / 1_000)
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
                        yield(process, consumer_group, subscription_group, topic, partition)
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

                topics.each_value do |t_data|
                  t_data[:partitions] = t_data[:partitions].sort_by { |key, _| key }.to_h
                end

                cg_data[:topics] = topics.sort_by { |key, _| key }.to_h
              end

              # Ensure that all consumer groups are always in the same order
              stats.sort_by { |key, _| key }.to_h
            end
          end
        end
      end
    end
  end
end
