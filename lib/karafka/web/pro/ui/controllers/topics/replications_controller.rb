# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Topics
            # Controller responsible for viewing and managing topics replication details
            class ReplicationsController < BaseController
              self.sortable_attributes = %w[
                partition_id
                leader
                replica_count
                in_sync_replica_brokers
              ].freeze

              # Displays requested topic replication details
              #
              # @param topic_name [String] topic we're interested in
              def show(topic_name)
                @topic = Models::Topic.find(topic_name)

                @partitions = refine(@topic[:partitions])

                # Extract replication factor from the first partition (same for all partitions)
                # The partitions data is an array of hashes with :replica_count key
                first_partition = @topic[:partitions]&.first
                @replication_factor = first_partition&.fetch(:replica_count, 0) || 0

                # Fetch min.insync.replicas from topic config
                min_isr_config = @topic.configs.find { |c| c.name == 'min.insync.replicas' }
                @min_isr = min_isr_config&.value&.to_i || 1

                # Determine resilience issues (checked in priority order):
                # 1. No redundancy: RF = 1 (single point of failure, most severe)
                # 2. Zero write fault tolerance: RF > 1 but RF <= minISR (can't lose any broker)
                # 3. Low durability: RF > 1 and minISR = 1 (data loss risk if leader fails)
                @has_no_redundancy = @replication_factor == 1
                @has_zero_fault_tolerance = @replication_factor > 1 &&
                                            @replication_factor <= @min_isr
                @has_low_durability = @replication_factor > 1 && @min_isr == 1

                @has_resilience_issue = @has_zero_fault_tolerance ||
                                        @has_low_durability ||
                                        @has_no_redundancy

                render
              end
            end
          end
        end
      end
    end
  end
end
