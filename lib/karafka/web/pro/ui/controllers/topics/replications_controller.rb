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

                # Determine if there's a resilience issue (RF <= minISR means no fault tolerance)
                @has_resilience_issue = @replication_factor.positive? && @replication_factor <= @min_isr

                render
              end
            end
          end
        end
      end
    end
  end
end
