# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
