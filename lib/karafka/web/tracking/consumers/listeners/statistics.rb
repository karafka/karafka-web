# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener used to collect metrics published by librdkafka
          class Statistics < Base
            # Collect Kafka metrics
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_statistics_emitted(event)
              statistics = event[:statistics]
              topics = statistics.fetch('topics')
              cgrp = statistics.fetch('cgrp')
              consumer_group_id = event[:consumer_group_id]

              track do |sampler|
                cg_details = extract_consumer_group_details(consumer_group_id, cgrp)
                sampler.consumer_groups[consumer_group_id] = cg_details

                topics.each do |topic_name, topic_values|
                  partitions = topic_values.fetch('partitions')

                  partitions.each do |partition_name, partition_statistics|
                    partition_id = partition_name.to_i

                    next unless partition_reportable?(partition_id, partition_statistics)

                    metrics = extract_partition_metrics(partition_statistics)

                    next if metrics.empty?

                    topics_details = cg_details[:topics]

                    topic_details = topics_details[topic_name] ||= {
                      name: topic_name,
                      partitions: {}
                    }

                    topic_details[:partitions][partition_id] = metrics.merge(
                      id: partition_id,
                      poll_state: poll_state(consumer_group_id, topic_name, partition_id)
                    )
                  end
                end
              end
            end

            private

            # Extracts basic consumer group related details
            # @param consumer_group_id [String]
            # @param consumer_group_statistics [Hash]
            # @return [Hash] consumer group relevant details
            def extract_consumer_group_details(consumer_group_id, consumer_group_statistics)
              {
                id: consumer_group_id,
                state: consumer_group_statistics.slice(
                  'state',
                  'join_state',
                  'stateage',
                  'rebalance_age',
                  'rebalance_cnt',
                  'rebalance_reason'
                ),
                topics: {}
              }
            end

            # @param partition_id [Integer]
            # @param partition_statistics [Hash]
            # @return [Boolean] is this partition relevant to the current process, hence should we
            #   report about it in the context of the process.
            def partition_reportable?(partition_id, partition_statistics)
              return false if partition_id == -1

              # Skip until lag info is available
              return false if partition_statistics['consumer_lag'] == -1

              # Collect information only about what we are subscribed to and what we fetch or
              # work in any way. Stopped means, we no longer work with it
              return false if partition_statistics['fetch_state'] == 'stopped'

              true
            end

            # Extracts and formats partition relevant metrics
            #
            # @param partition_statistics [Hash]
            # @return [Hash] extracted partition metrics
            def extract_partition_metrics(partition_statistics)
              metrics = partition_statistics.slice(
                'consumer_lag_stored',
                'consumer_lag_stored_d',
                'committed_offset',
                'stored_offset',
                'fetch_state'
              )

              # Rename as we do not need `consumer_` prefix
              metrics.transform_keys! { |key| key.gsub('consumer_', '') }
              metrics.transform_keys!(&:to_sym)

              metrics
            end

            # @param consumer_group_id [String]
            # @param topic_name [String]
            # @param partition_id [Integer]
            # @return [String] poll state / is partition paused or not
            def poll_state(consumer_group_id, topic_name, partition_id)
              pause_id = [consumer_group_id, topic_name, partition_id].join('-')

              sampler.pauses.include?(pause_id) ? 'paused' : 'active'
            end
          end
        end
      end
    end
  end
end
