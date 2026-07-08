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
              compensate_paused_partitions_lag(state, stats)

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

            # Overlays freshly-queried lag data (computed by the materializer for partitions
            # that have been paused long enough for their librdkafka high watermark cache to go
            # stale) on top of the self-reported values for those partitions.
            #
            # @param state [Hash]
            # @param stats [Hash] hash where we will store all the aggregated data
            # @note Consumer group ids, topic names and stringified partition ids in
            #   `state[:paused_partitions_lag]` come back from `state` as symbols because it went
            #   through a JSON round-trip via our deserializer, unlike the string/integer keys
            #   used in `stats`.
            def compensate_paused_partitions_lag(state, stats)
              corrections = state[:paused_partitions_lag]

              return if corrections.nil? || corrections.empty?

              stats.each do |cg_id, cg_data|
                cg_corrections = corrections[cg_id.to_sym]

                next unless cg_corrections

                cg_data[:topics].each do |t_name, t_data|
                  topic_corrections = cg_corrections[t_name.to_sym]

                  next unless topic_corrections

                  t_data[:partitions].each do |pt_id, partition|
                    next unless partition[:poll_state] == "paused"

                    correction = topic_corrections[pt_id.to_s.to_sym]

                    next unless correction

                    apply_paused_partition_lag_correction(partition, correction)
                  end
                end
              end
            end

            # @param partition [Partition]
            # @param correction [Hash] freshly computed `lag`/`lag_stored`, whichever were
            #   available at the time the materializer queried the cluster
            def apply_paused_partition_lag_correction(partition, correction)
              partition[:lag] = correction[:lag] if correction[:lag]
              partition[:lag_stored] = correction[:lag_stored] if correction[:lag_stored]

              # Same hybrid-selection rule as `Partition#lag_hybrid`
              partition[:lag_hybrid] = partition[:lag_stored].negative? ? partition[:lag] : partition[:lag_stored]

              # A substituted single-point value has no meaningful trend
              partition[:lag_d] = 0
              partition[:lag_stored_d] = 0
              partition[:lag_hybrid_d] = 0
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
