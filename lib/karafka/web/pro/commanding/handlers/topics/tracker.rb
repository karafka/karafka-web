# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          # Namespace for handling requests related to topic-level operations
          module Topics
            # Tracker used to record incoming topic related operational requests until they are
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
              # @note Commands are indexed by consumer_group_id:topic combination since topic
              #   commands are dispatched without subscription_group_id.
              def <<(command)
                key = "#{command[:consumer_group_id]}:#{command[:topic]}"

                @mutex.synchronize do
                  @requests[key] << command
                end
              end

              # Selects all incoming command requests that match the given consumer group and topic
              # and iterates over them. It removes selected requests during iteration.
              #
              # @param consumer_group_id [String]
              # @param topic [String]
              #
              # @yieldparam [Request] given command request
              def each_for(consumer_group_id, topic, &)
                key = "#{consumer_group_id}:#{topic}"
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
