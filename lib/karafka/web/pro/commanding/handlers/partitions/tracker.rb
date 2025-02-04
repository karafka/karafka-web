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

              # Empty hash for internal usage
              EMPTY_HASH = {}.freeze

              private_constant :EMPTY_HASH

              def initialize
                @mutex = Mutex.new
                @requests = Hash.new { |h, k| h[k] = {} }
              end

              def each_for(subscription_group_id)
                (delete(subscription_group_id) || EMPTY_HASH).each_value do |details|
                  yield(details)
                end
              end

              def <<(details)
                subscription_group_id = details.fetch(:subscription_group_id)
                topic = details.fetch(:topic)
                partition_id = details.fetch(:partition_id)
                key = key(topic, partition_id)

                @mutex.synchronize do
                  @requests[subscription_group_id][key] = details
                end
              end

              private

              def delete(subscription_group_id)
                @mutex.synchronize do
                  @requests.delete(subscription_group_id)
                end
              end

              def key(topic, partition_id)
                [
                  topic,
                  partition_id
                ].map(&:to_s).join
              end
            end
          end
        end
      end
    end
  end
end
