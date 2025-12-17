# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Topics
            # Listener that hooks to the connection listener fetch loop flow to adjust it prior
            # to the next polling or on rebalances to execute the topic specific commands.
            class Listener
              def initialize
                @tracker = Tracker.instance
                @executor = Executor.new
              end

              # Connects to the fetching loop pre-fetch and executes requested commands before
              # polling (if any).
              #
              # @param event [Karafka::Core::Monitoring::Event]
              def on_connection_listener_fetch_loop(event)
                listener = event[:caller]
                client = event[:client]
                subscription_group = listener.subscription_group
                consumer_group_id = subscription_group.consumer_group.id

                # Iterate over all topics in this subscription group and check for commands
                subscription_group.topics.each do |topic|
                  @tracker.each_for(consumer_group_id, topic.name) do |command|
                    @executor.call(listener, client, command)
                  end
                end
              end

              # Creates a rebalance barrier, so we do not execute any commands in between
              # rebalances. This prevents us from aggregating old and outdated requests.
              #
              # Rejects all the commands if there were any waiting.
              # @param event [Karafka::Core::Monitoring::Event]
              def on_rebalance_partitions_assigned(event)
                subscription_group = event[:subscription_group]
                consumer_group_id = subscription_group.consumer_group.id

                subscription_group.topics.each do |topic|
                  @tracker.each_for(consumer_group_id, topic.name) do |command|
                    @executor.reject(command)
                  end
                end
              end

              # @param event [Karafka::Core::Monitoring::Event]
              # @see `#on_rebalance_partitions_assigned`
              def on_rebalance_partitions_revoked(event)
                on_rebalance_partitions_assigned(event)
              end
            end
          end
        end
      end
    end
  end
end
