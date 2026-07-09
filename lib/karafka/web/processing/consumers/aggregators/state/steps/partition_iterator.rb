# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Shared partition-tree walk for steps that need per-partition report data
              # together with its consumer group / topic / partition id context.
              module PartitionIterator
                private

                # @param report [Hash]
                # @param block [Proc]
                # @yieldparam partition_stats [Hash] statistics for a single partition
                # @yieldparam cg_id [Symbol] consumer group id this partition belongs to
                # @yieldparam topic_name [Symbol] topic name this partition belongs to
                # @yieldparam pt_id [Symbol] partition id (as reported, not normalized)
                def iterate_partitions(report, &block)
                  report[:consumer_groups].each do |cg_id, consumer_group|
                    consumer_group[:subscription_groups].each_value do |subscription_group|
                      subscription_group[:topics].each do |topic_name, topic|
                        topic[:partitions].each do |pt_id, partition_stats|
                          block.call(partition_stats, cg_id, topic_name, pt_id)
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
end
