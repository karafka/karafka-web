# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Enrichers
            # Enriches consumer groups data with polling details and transactional consumer handling
            # This is responsible for materializing time-based data and filling statistical gaps
            # for transactional consumers
            class ConsumerGroups < Base
              include ::Karafka::Core::Helpers::Time

              # @param consumer_groups [Hash] consumer groups hash to be enriched
              # @param subscription_groups [Hash] subscription groups tracking data
              def initialize(consumer_groups, subscription_groups)
                super()
                @consumer_groups = consumer_groups
                @subscription_groups = subscription_groups
              end

              # Enriches consumer groups with polling details and transactional consumer offsets
              # @return [Hash] enriched consumer groups
              def call
                consumer_groups.each_value do |cg_details|
                  cg_details.each do
                    cg_details.fetch(:subscription_groups, {}).each do |sg_id, sg_details|
                      enrich_subscription_group(sg_id, sg_details)
                    end
                  end
                end

                consumer_groups
              end

              private

              attr_reader :consumer_groups, :subscription_groups

              # Enriches a single subscription group with polling age and partition details
              # @param sg_id [String] subscription group id
              # @param sg_details [Hash] subscription group details from statistics
              def enrich_subscription_group(sg_id, sg_details)
                # This should be always available, since the subscription group polled at time
                # is first initialized before we start polling, there should be no case where
                # we have statistics about a given subscription group but we do not have the
                # sg reference
                sg_tracking = subscription_groups.fetch(sg_id)

                polled_at = sg_tracking.fetch(:polled_at)
                sg_details[:state][:poll_age] = (monotonic_now - polled_at).round(2)
                sg_details[:state][:poll_interval] = sg_tracking[:poll_interval]
                sg_details[:instance_id] = sg_tracking[:instance_id]

                sg_details[:topics].each do |topic_name, topic_details|
                  topic_details[:partitions].each do |partition_id, partition_details|
                    enrich_partition(sg_tracking, topic_name, partition_id, partition_details)
                  end
                end
              end

              # Enriches partition details for transactional consumers
              # @param sg_tracking [Hash] subscription group tracking data
              # @param topic_name [String] topic name
              # @param partition_id [Integer] partition id
              # @param partition_details [Hash] partition details from statistics
              def enrich_partition(sg_tracking, topic_name, partition_id, partition_details)
                # Always assume non-transactional as default. Will be overwritten by the
                # consumer level details if collected
                partition_details[:transactional] ||= false

                # If we have stored offset or stored lag, it means it's not a transactional
                # consumer at all so we can skip enrichment
                return if partition_details[:lag_stored].positive?
                return if partition_details[:stored_offset].positive?
                return unless sg_tracking[:topics].key?(topic_name)
                return unless sg_tracking[:topics][topic_name].key?(partition_id)

                k_partition_details = sg_tracking[:topics][topic_name][partition_id]

                # If seek offset was not yet set, nothing to enrich
                return unless k_partition_details[:seek_offset].positive?

                enrich_transactional_partition(k_partition_details, partition_details)
              end

              # Enriches partition with transactional consumer offset details
              # @param k_partition_details [Hash] Karafka-level partition details
              # @param partition_details [Hash] partition details from statistics
              def enrich_transactional_partition(k_partition_details, partition_details)
                partition_details[:transactional] = k_partition_details[:transactional]

                # Seek offset is always +1 from the last stored in Karafka
                seek_offset = k_partition_details[:seek_offset]
                stored_offset = seek_offset - 1

                # In case of transactions we have to compute the lag ourselves
                # -1 because ls offset (or high watermark) is last + 1
                lag = partition_details[:ls_offset] - seek_offset
                # This can happen if ls_offset is refreshed slower than our stored offset
                # fetching from Karafka transactional layer
                lag = 0 if lag.negative?

                partition_details[:lag] = lag
                partition_details[:lag_d] = 0
                partition_details[:lag_stored] = lag
                partition_details[:lag_stored_d] = 0
                partition_details[:stored_offset] = stored_offset
                partition_details[:committed_offset] = stored_offset
              end
            end
          end
        end
      end
    end
  end
end
