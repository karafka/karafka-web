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
              # @note We accumulate requests per subscription group because this is the layer of
              #   applicability of those even for partition related requests.
              def <<(command)
                @mutex.synchronize do
                  @requests[command[:subscription_group_id]] << command
                end
              end

              # Selects all incoming command requests for given subscription group and iterates
              # over them. It removes selected requests during iteration.
              #
              # @param subscription_group_id [String] id of the subscription group for which we
              #   want to get all the requests. Subscription groups ids (not names) are unique
              #   within the application, so it is unique "enough".
              #
              # @yieldparam [Request] given command request for the requested subscription group
              def each_for(subscription_group_id, &)
                requests = nil

                @mutex.synchronize do
                  requests = @requests.delete(subscription_group_id)
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
