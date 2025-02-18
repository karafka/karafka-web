# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Partitions
            # Listener that hooks to the connection listener fetch loop flow to adjust it prior
            # to the next pooling or on rebalances to execute the partition specific commands.
            class Listener
              def initialize
                @tracker = Tracker.instance
                @executor = Executor.new
              end

              # Connects to the fetching loop pre-fetch and executes requested commands before
              # pooling (if any).
              #
              # @param event [Karafka::Core::Monitoring::Event]
              def on_connection_listener_fetch_loop(event)
                listener = event[:caller]
                client = event[:client]

                @tracker.each_for(listener.subscription_group.id) do |command|
                  @executor.call(listener, client, command)
                end
              end

              # Creates a rebalance barrier, so we do not execute any commands in between
              # rebalances. This prevents us from aggregating old and outdated requests.
              #
              # Rejects all the commands if there were any waiting.
              # @param event [Karafka::Core::Monitoring::Event]
              def on_rebalance_partitions_assigned(event)
                @tracker.each_for(event[:subscription_group_id]) do |command|
                  @executor.reject(command)
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
