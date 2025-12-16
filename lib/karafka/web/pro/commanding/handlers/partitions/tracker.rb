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
              end

              # Adds the given command into the tracker so it can be retrieved when needed.
              #
              # @param command [Request] command we want to schedule
              # @note Commands are indexed by consumer_group_id:topic:partition_id combination since
              #   partition commands are dispatched without subscription_group_id.
              def <<(command)
                key = "#{command[:consumer_group_id]}:#{command[:topic]}:#{command[:partition_id]}"

                @mutex.synchronize do
                  @requests[key] << command
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
                requests = nil

                @mutex.synchronize do
                  requests = @requests.delete(key)
                end

                (requests || EMPTY_ARRAY).each(&)
              end
            end
          end
        end
      end
    end
  end
end
