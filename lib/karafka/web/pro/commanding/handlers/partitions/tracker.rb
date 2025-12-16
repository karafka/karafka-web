# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Partitions
            # Tracker used to record incoming partition related operational requests until they are
            # executable or invalid. It stores the requests as they come for execution pre-polling.
            class Tracker
              include Singleton

              # Empty array for internal usage
              EMPTY_ARRAY = [].freeze

              private_constant :EMPTY_ARRAY

              def initialize
                @mutex = Mutex.new
                @requests = Hash.new { |h, k| h[k] = [] }
                # Index tracking which partitions have pending commands per consumer_group:topic
                @partition_index = Hash.new { |h, k| h[k] = Set.new }
              end

              # Adds the given command into the tracker so it can be retrieved when needed.
              #
              # @param command [Request] command we want to schedule
              # @note Commands are indexed by consumer_group_id:topic:partition_id combination since
              #   partition commands are dispatched without subscription_group_id.
              def <<(command)
                key = "#{command[:consumer_group_id]}:#{command[:topic]}:#{command[:partition_id]}"
                index_key = "#{command[:consumer_group_id]}:#{command[:topic]}"

                @mutex.synchronize do
                  @requests[key] << command
                  @partition_index[index_key] << command[:partition_id]
                end
              end

              # Selects all incoming command requests for given consumer group, topic, and partition
              # and iterates over them. It removes selected requests during iteration.
              #
              # @param consumer_group_id [String]
              # @param topic [String]
              # @param partition_id [Integer]
              #
              # @yieldparam [Request] given command request
              def each_for(consumer_group_id, topic, partition_id, &)
                key = "#{consumer_group_id}:#{topic}:#{partition_id}"
                index_key = "#{consumer_group_id}:#{topic}"
                requests = nil

                @mutex.synchronize do
                  requests = @requests.delete(key)
                  @partition_index[index_key].delete(partition_id) if requests
                end

                (requests || EMPTY_ARRAY).each(&)
              end

              # Returns partition IDs that have pending commands for the given consumer group and topic
              #
              # @param consumer_group_id [String]
              # @param topic [String]
              # @return [Array<Integer>] partition IDs with pending commands
              def partition_ids_for(consumer_group_id, topic)
                index_key = "#{consumer_group_id}:#{topic}"

                @mutex.synchronize do
                  @partition_index[index_key].to_a
                end
              end

              # Clears all stored requests and partition index
              # @note Primarily for testing purposes
              def clear!
                @mutex.synchronize do
                  @requests.clear
                  @partition_index.clear
                end
              end
            end
          end
        end
      end
    end
  end
end
