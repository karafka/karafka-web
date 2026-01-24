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
            # Namespace for topic related commands
            module Commands
              # Base class for all the topic related commands handlers
              class Base
                # @param listener [Karafka::Connection::Listener] listener that handles given
                #   topic in the context of given subscription group
                # @param client [Karafka::Connection::Client] underlying Kafka client
                # @param request [Request] command request
                def initialize(listener, client, request)
                  @listener = listener
                  @client = client
                  @request = request
                end

                # Runs the command
                def call
                  raise NotImplementedError, 'Implement in a subclass'
                end

                private

                attr_reader :listener, :client, :request

                # @return [String] name of the topic on which the command should be applied
                def topic
                  @topic ||= request[:topic]
                end

                # Finds all partition IDs for the target topic that are currently assigned
                # to this listener's subscription group.
                #
                # @return [Array<Integer>] array of partition IDs assigned to this process for
                #   the target topic
                def owned_partition_ids
                  @owned_partition_ids ||= begin
                    assignment = client.assignment

                    # assignment is a TopicPartitionList from rdkafka
                    # We need to find partitions that match our target topic
                    assignment.to_h.fetch(topic, []).map(&:partition)
                  end
                end

                # Gets or creates a coordinator for a given partition
                #
                # @param partition_id [Integer] partition ID
                # @return [Karafka::Processing::Coordinator, Karafka::Pro::Processing::Coordinator]
                def coordinator_for(partition_id)
                  listener.coordinators.find_or_create(topic, partition_id)
                end

                # @return [String] id of the current consumer process
                def process_id
                  @process_id ||= ::Karafka::Web.config.tracking.consumers.sampler.process_id
                end

                # Publishes the execution result back to Kafka
                #
                # @param status [String] execution status
                # @param partitions_affected [Array<Integer>] partition IDs that were affected
                # @param partitions_prevented [Array<Integer>] partition IDs that were skipped
                #   due to prevent_override setting
                def result(status, partitions_affected: [], partitions_prevented: [])
                  Commanding::Dispatcher.result(
                    request.name,
                    process_id,
                    request.to_h.merge(
                      status: status,
                      partitions_affected: partitions_affected,
                      partitions_prevented: partitions_prevented
                    )
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
