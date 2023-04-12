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
              cg_id = event[:consumer_group_id]
              sg_id = event[:subscription_group_id]
              sg_details = extract_sg_details(sg_id, cgrp)

              # More than one subscription group from the same consumer group may be reporting
              # almost the same time. To prevent corruption of partial data, we put everything here
              # in track as we merge data from multiple subscription groups
              track do |sampler|
                topics.each do |topic_name, topic_values|
                  partitions = topic_values.fetch('partitions')

                  partitions.each do |pt_name, pt_stats|
                    pt_id = pt_name.to_i

                    next unless partition_reportable?(pt_id, pt_stats)

                    metrics = extract_partition_metrics(pt_stats)

                    next if metrics.empty?

                    topics_details = sg_details[:topics]

                    topic_details = topics_details[topic_name] ||= {
                      name: topic_name,
                      partitions: {}
                    }

                    topic_details[:partitions][pt_id] = metrics.merge(
                      id: pt_id,
                      # Pauses are stored on a consumer group since we do not process same topic
                      # twice in the multiple subscription groups
                      poll_state: poll_state(cg_id, topic_name, pt_id)
                    )
                  end
                end

                sampler.consumer_groups[cg_id] ||= {
                  id: cg_id,
                  subscription_groups: {}
                }

                sampler.consumer_groups[cg_id][:subscription_groups][sg_id] = sg_details
              end
            end

            private

            # Extracts basic consumer group related details
            # @param sg_id [String]
            # @param sg_stats [Hash]
            # @return [Hash] consumer group relevant details
            def extract_sg_details(sg_id, sg_stats)
              {
                id: sg_id,
                state: sg_stats.slice(
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

            # @param pt_id [Integer]
            # @param pt_stats [Hash]
            # @return [Boolean] is this partition relevant to the current process, hence should we
            #   report about it in the context of the process.
            def partition_reportable?(pt_id, pt_stats)
              return false if pt_id == -1

              # Collect information only about what we are subscribed to and what we fetch or
              # work in any way. Stopped means, we stopped working with it
              return false if pt_stats['fetch_state'] == 'stopped'

              # Return if we no longer fetch this partition in a particular process. None means
              # that we no longer have this subscription assigned and we do not fetch
              return false if pt_stats['fetch_state'] == 'none'

              true
            end

            # Extracts and formats partition relevant metrics
            #
            # @param pt_stats [Hash]
            # @return [Hash] extracted partition metrics
            def extract_partition_metrics(pt_stats)
              metrics = pt_stats.slice(
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

            # @param cg_id [String]
            # @param topic_name [String]
            # @param pt_id [Integer]
            # @return [String] poll state / is partition paused or not
            def poll_state(cg_id, topic_name, pt_id)
              pause_id = [cg_id, topic_name, pt_id].join('-')

              sampler.pauses.include?(pause_id) ? 'paused' : 'active'
            end
          end
        end
      end
    end
  end
end
