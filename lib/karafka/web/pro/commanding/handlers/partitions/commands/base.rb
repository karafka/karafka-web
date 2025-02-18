# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          # Namespace for commands related to specific partitions
          module Partitions
            # Namespace for partitions related commands
            module Commands
              # Base class for all the partition related commands handlers
              class Base
                # @param listener [Karafka::Connection::Listener] listener that handles given
                #   partition in the context of given subscription group
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

                # @return [String] partition for which the command should be applied
                def partition_id
                  @partition_id ||= request[:partition_id]
                end

                # @return [Karafka::Processing::Coordinator, Karafka::Pro::Processing::Coordinator]
                def coordinator
                  @coordinator ||= listener.coordinators.find_or_create(topic, partition_id)
                end

                # Publishes the execution result back to Kafka
                # @param status [String] execution status
                def result(status)
                  Commanding::Dispatcher.result(
                    request.name,
                    ::Karafka::Web.config.tracking.consumers.sampler.process_id,
                    request.to_h.merge(status: status)
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
