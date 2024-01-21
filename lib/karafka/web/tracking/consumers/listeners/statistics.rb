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

              track_transfers(statistics)

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
                      id: pt_id
                    ).merge(
                      # Pauses are stored on a consumer group since we do not process same topic
                      # twice in the multiple subscription groups
                      poll_details(sg_id, topic_name, pt_id)
                    )
                  end
                end

                sampler.consumer_groups[cg_id][:subscription_groups][sg_id] = sg_details
              end
            end

            private

            # Tracks network transfers from and to the client using a 1 minute rolling window
            #
            # @param statistics [Hash] statistics hash
            def track_transfers(statistics)
              brokers = statistics.fetch('brokers', {})

              return if brokers.empty?

              track do |sampler|
                client_name = statistics.fetch('name')

                brokers.each do |broker_name, values|
                  scope_name = "#{client_name}-#{broker_name}"

                  sampler.windows.m1["#{scope_name}-rxbytes"] << values.fetch('rxbytes', 0)
                  sampler.windows.m1["#{scope_name}-txbytes"] << values.fetch('txbytes', 0)
                end
              end
            end

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
                ).transform_keys(&:to_sym),
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
                'consumer_lag',
                'consumer_lag_d',
                'consumer_lag_stored',
                'consumer_lag_stored_d',
                'committed_offset',
                # Can be useful to track the frequency of flushes when there is progress
                'committed_offset_fd',
                'stored_offset',
                # Can be useful to track the frequency of flushes when there is progress
                'stored_offset_fd',
                'fetch_state',
                'hi_offset',
                'hi_offset_fd',
                'lo_offset',
                'eof_offset',
                'ls_offset',
                # Two below can be useful for detection of hanging transactions
                'ls_offset_d',
                'ls_offset_fd'
              )

              # Rename as we do not need `consumer_` prefix
              metrics.transform_keys! { |key| key.gsub('consumer_', '') }
              metrics.transform_keys!(&:to_sym)

              metrics
            end

            # @param sg_id [String] subscription group id
            # @param topic_name [String]
            # @param pt_id [Integer] partition id
            # @return [String] poll state / is partition paused or not
            def poll_details(sg_id, topic_name, pt_id)
              pause_id = [sg_id, topic_name, pt_id].join('-')

              details = { poll_state: 'active', poll_state_ch: 0 }

              pause_details = sampler.pauses[pause_id]

              return details unless pause_details

              {
                poll_state: 'paused',
                poll_state_ch: [(pause_details.fetch(:paused_till) - monotonic_now).round, 0].max
              }
            end
          end
        end
      end
    end
  end
end
