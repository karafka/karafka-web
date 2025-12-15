# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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

                # @return [String] consumer group ID from the request
                def consumer_group_id
                  @consumer_group_id ||= request[:consumer_group_id]
                end

                # Checks if this listener's subscription group belongs to the target consumer group.
                # This is important for topic-level commands that are broadcast to all processes,
                # as we need to filter by consumer group to avoid affecting other consumer groups
                # that may be consuming the same topic.
                #
                # @return [Boolean] true if this listener should process the command
                def matches_consumer_group?
                  listener.subscription_group.consumer_group.id == consumer_group_id
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
                # @param partitions_prevented [Array<Integer>] partition IDs that were skipped due to
                #   prevent_override setting
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
